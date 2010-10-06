module Coupler
  module Models
    class Scenario
      class RubyRunner
        LIMIT = 10000

        def initialize(parent)
          @parent = parent
          @resources = parent.resources
          @type = parent.linkage_type
        end

        def run!
          # Set up needed tables; this should go in Scenario
          @parent.local_database do |db|
            group_counter = GroupCounter.new
            run_count = @parent.run_count + 1

            # Create the groups table and get field pairs
            pairs = {}
            groups_columns = [
              {:name => :id, :type => Integer},
              {:name => :resource_id, :type => Integer},
              {:name => :matcher_id, :type => Integer},
            ]
            @parent.matchers.each do |matcher|
              matcher_pairs = []
              matcher.comparisons.each do |comparison|
                if !comparison.blocking?
                  fields = comparison.fields
                  matcher_pairs << fields
                  groups_columns.push(fields[0].local_column_options.merge(:name => :"field_#{fields[0].id}"))
                  if fields[1] != fields[0]
                    groups_columns.push(fields[1].local_column_options.merge(:name => :"field_#{fields[1].id}"))
                  end
                end
              end
              pairs[matcher.id] = matcher_pairs
            end
            groups_name = :"groups_#{run_count}"
            db.create_table!(groups_name) do
              columns.push(*groups_columns)
            end
            groups_dataset = db[groups_name]
            groups_buffer = ImportBuffer.new(groups_columns.collect { |c| c[:name] }, groups_dataset)

            # Create the groups/records join table
            groups_records_name = :"groups_records_#{run_count}"
            db.create_table!(groups_records_name) do
              String :record_id
              Integer :group_id, :index => true
            end
            groups_records_dataset = db[groups_records_name]
            groups_records_buffer = ImportBuffer.new([:record_id, :group_id], groups_records_dataset)

            @parent.matchers.each do |matcher|
              comparisons = matcher.comparisons
              matcher_pairs = pairs[matcher.id]

              # Group records for each dataset.  This step is the same for both
              # self-linkage and dual-linkage.  However, this is the only step
              # for self-linkage.  Dual-linkage requires another pass after
              # this.
              tw = ThreadsWait.new
              @resources.each_with_index do |resource, i|
                which = @type == 'self-linkage' ? nil : i
                thr = Thread.new(resource, which) do |resource, which| # I don't care that I'm overwriting variables here
                  segments = nil
                  workers = []
                  record_matcher = RecordMatcher.new(
                    group_counter, groups_buffer, groups_records_buffer,
                    resource, matcher, pairs,
                    @type == 'self-linkage' ? nil : i
                  )
                  resource.final_dataset do |dataset|
                    # Apply filters and what not from comparisons
                    primary_key = resource.primary_key_sym
                    dataset = dataset.select(primary_key)
                    comparisons.each do |comparison|
                      dataset = comparison.apply(dataset, which)
                    end
                    dataset = dataset.order_more(primary_key)

                    local_tw = ThreadsWait.new
                    count = dataset.count
                    segments = count / LIMIT
                    segments += 1  if count % LIMIT > 0

                    segments.times do |j|
                      ds = dataset.limit(LIMIT, LIMIT * j)
                      worker = GroupWorker.new(ds, record_matcher, j > 0, j < (segments - 1))
                      workers << worker
                      local_tw.join_nowait(worker.run)
                      local_tw.next_wait    if local_tw.threads.length == 10
                    end
                    local_tw.all_waits
                  end
                  records_groups_buffer.flush
                  groups_buffer.flush

                  # Compare heads and tails from segments
                  if segments > 1
                    head = tail = nil
                    workers.each_with_index do |worker, j|
                      if j > 0
                        head = worker.head
                        if record_matcher.compare(tail[:row], head[:row]) == 0
                          groups_records_dataset.filter({
                            :group_id => head[:group_id]
                          }).update(:group_id => tail[:group_id])
                          groups_dataset.filter({
                            :id => head[:group_id]
                          }).delete
                        end
                      end
                      tail = worker.tail
                    end
                  end
                end
                thr.abort_on_exception = true
                tw.join_nowait(thr)
              end
              tw.all_waits

              # For dual-linkage, now we have to compare groups.
            end
          end
        end
      end
    end
  end
end

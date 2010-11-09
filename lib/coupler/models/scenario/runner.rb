module Coupler
  module Models
    class Scenario
      class Runner
        LIMIT = 10000

        def initialize(parent)
          @parent = parent
          @matcher = parent.matcher
          if @matcher.cross_match?
            @resources = [parent.resource_1, parent.resource_1]
            @type = 'cross-linkage'
          else
            @resources = parent.resources
            @type = parent.linkage_type
          end
          @run_number = @parent.run_count + 1
          @mutex = Mutex.new
          @group_number = 0
          setup_pairs
          create_tables
        end

        def run!
          @parent.local_database do |scenario_db|
            @groups_dataset = scenario_db[@groups_table_name]
            @groups_buffer = ImportBuffer.new(@groups_column_names, @groups_dataset)
            @join_dataset = scenario_db[@join_table_name]
            @join_buffer = ImportBuffer.new([:record_id, :resource_id, :group_id], @join_dataset)

            # Group records for each dataset.  This step is the same for both
            # self-linkage and dual-linkage.  However, this is the only step
            # for self-linkage.  Dual-linkage requires another pass after
            # this.
            #
            # Cross-matching on a single dataset is treated as a dual-linkage.
            #
            @pairs = @phase_one_pairs
            tw = ThreadsWait.new
            databases_to_close = []
            @resources.each_with_index do |resource, i|
              dataset = resource.final_dataset
              databases_to_close << dataset.db
              primary_key = resource.primary_key_sym
              which = @type == 'self-linkage' ? nil : i

              resource_thread = phase_one_thread(dataset, primary_key, resource.id, which)
              tw.join_nowait(resource_thread)
            end
            tw.all_waits
            databases_to_close.each do |db|   # tidy up
              db.disconnect
              ::Sequel::DATABASES.delete(db)
            end

            if @type != 'self-linkage'
              # Phase 2!
              @join_buffer = ImportBuffer.new([:group_1_id, :group_2_id], scenario_db[@secondary_groups_table_name])
              @pairs = @phase_two_pairs
              phase_two(@groups_dataset, :id)
              @join_buffer.flush
            end
          end
        end

        private
          def setup_pairs
            @field_pairs = []
            @phase_one_pairs = []
            @phase_two_pairs = @type == 'self-linkage' ? nil : []
            @matcher.comparisons.each do |comparison|
              if !comparison.blocking?
                fields = comparison.fields
                @field_pairs << fields
                @phase_one_pairs.push(fields.collect(&:name_sym))
                if @phase_two_pairs
                  pair_sym = :"pair_#{@phase_two_pairs.length}"
                  @phase_two_pairs.push([pair_sym, pair_sym])
                end
              end
            end
          end

          def create_tables
            # Yes, this could be done during setup_pairs, but I think
            # this is more clean.  Also, there will only be very few pairs.
            groups_columns = [
              {:name => :id, :type => Integer, :primary_key => true},
              {:name => :resource_id, :type => Integer}
            ]
            @group_value_fields = []
            @field_pairs.each_with_index do |(field_1, field_2), i|
              type_1 = field_1.local_column_options[:type]
              type_2 = field_2.local_column_options[:type]
              if type_1 != type_2
                # FIXME!
                raise "BOOM!!"
              end
              @group_value_fields.push([field_1.name_sym, field_2.name_sym])
              groups_columns.push({:name => :"pair_#{i}", :type => type_1})
            end
            @groups_column_names = groups_columns.collect { |c| c[:name] }
            @groups_table_name = :"groups_#{@run_number}"

            key_types = @resources.collect { |r| r.primary_key_type }.uniq
            record_id_type = key_types.length == 1 ? key_types[0] : String
            @join_table_name = :"groups_records_#{@run_number}"

            @parent.local_database do |scenario_db|
              scenario_db.create_table!(@groups_table_name) do
                columns.push(*groups_columns)
              end
              scenario_db.create_table!(@join_table_name) do
                column :record_id, record_id_type
                Integer :resource_id
                Integer :group_id, :index => true
              end
              if @type != 'self-linkage'
                # Need another groups table
                @secondary_groups_table_name = :"groups_groups_#{@run_number}"
                scenario_db.create_table!(@secondary_groups_table_name) do
                  Integer :group_1_id
                  Integer :group_2_id
                end
              end
            end
          end

          def phase_one_thread(dataset, primary_key, resource_id, which)
            thread = Thread.new do
              # Apply filters and what not from comparisons
              dataset = dataset.select(primary_key)
              @matcher.comparisons.each do |comparison|
                dataset = comparison.apply(dataset, which)
              end
              dataset = dataset.order_more(primary_key)

              # Do the work
              local_tw = ThreadsWait.new
              threads = []
              count = dataset.count
              segments = count / LIMIT
              segments += 1  if count % LIMIT > 0

              segments.times do |segment_num|
                ds = dataset.limit(LIMIT, LIMIT * segment_num)
                thread = Thread.new do
                  prev_row = nil
                  group_id = nil

                  ds.each_with_index do |row, row_num|
                    if row_num > 0
                      result = compare_rows(prev_row, row, which)
                      if (result || which) && group_id.nil?
                        # If `which` is not nil, that means we're in the first
                        # stage of a dual-linkage.  So, we should save groups
                        # that only have 1 record in them.
                        group_id = create_group(resource_id, prev_row, which)
                        @join_buffer.add([prev_row[primary_key], resource_id, group_id])
                      end
                      if result
                        @join_buffer.add([row[primary_key], resource_id, group_id])
                      else
                        group_id = nil
                      end

                      # This stores the first record of this segment in order
                      # to check it against the last record of the previous
                      # segment.  I don't like putting this inside the loop
                      # really, but it's better than making another database
                      # query.
                      if segment_num > 0 && row_num == 1
                        Thread.current[:head] = { :row => prev_row, :group_id => group_id }
                      end
                    end
                    prev_row = row
                  end
                  if which && group_id.nil?
                    # See above comment about `which`
                    group_id = create_group(resource_id, prev_row, which)
                    @join_buffer.add([prev_row[primary_key], resource_id, group_id])
                  end

                  # This stores the last record of this segment in order to
                  # check it against the first record of the next segment.
                  if segment_num < (segments - 1)
                    Thread.current[:tail] = { :row => prev_row, :group_id => group_id }
                  end
                end
                thread.abort_on_exception = true
                threads << thread
                local_tw.join_nowait(thread)
                local_tw.next_wait    if local_tw.threads.length == 10
              end
              local_tw.all_waits
              @groups_buffer.flush
              @join_buffer.flush

              # Compare heads and tails from segments
              if segments > 1
                head = tail = nil
                threads.each do |thread|
                  if tail
                    head = thread[:head]
                    if compare_rows(tail, head, which)
                      @join_dataset.filter({
                        :group_id => head[:group_id]
                      }).update(:group_id => tail[:group_id])
                      @groups_dataset.filter({
                        :id => head[:group_id]
                      }).delete
                    end
                  end
                  tail = thread[:tail]
                end
              end
            end
            thread.abort_on_exception = true
            thread
          end

          def phase_two(dataset, primary_key)
            # Add sorting only
            @pairs.each do |fields|
              dataset = dataset.order_more(*fields.uniq)
            end
            dataset = dataset.order_more(primary_key)
            p dataset

            local_tw = ThreadsWait.new
            threads = []
            count = dataset.count
            segments = count / LIMIT
            segments += 1  if count % LIMIT > 0

            segments.times do |segment_num|
              ds = dataset.limit(LIMIT, LIMIT * segment_num)
              thread = Thread.new do
                prev_result = nil
                prev_row    = nil
                skip        = false

                ds.each_with_index do |row, row_num|
                  if row_num > 0 && !skip
                    result = compare_rows(prev_row, row)
                    # There should only be one-to-one matches here.
                    if result
                      @join_buffer.add([prev_row[primary_key], row[primary_key]])
                      skip = true  # Skip comparing this row to the next
                    end

                    if segment_num > 0 && row_num == 1 && !result
                      Thread.current[:head] = { :row => prev_row }
                    end
                  elsif skip
                    skip = false
                  end
                  prev_row = row
                  prev_result = result
                end
                if segment_num < (segments - 1) && !prev_result
                  Thread.current[:tail] = { :row => prev_row }
                end
              end
              thread.abort_on_exception = true
              threads << thread
              local_tw.join_nowait(thread)
              local_tw.next_wait    if local_tw.threads.length == 10
            end
            local_tw.all_waits
            @join_buffer.flush

            # Compare heads and tails from segments
            if threads.length > 1
              head = tail = nil
              threads.each do |thread|
                if tail
                  head = thread[:head]
                  if head && compare_rows(tail[:row], head[:row])
                    @join_buffer.add([tail[:row][primary_key], head[:row][primary_key]])
                  end
                end
                tail = thread[:tail]
              end
            end
          end

          def compare_rows(row_1, row_2, which = nil)
            values = []
            @pairs.each do |fields|
              value_1 = row_1[fields[which || 0]]
              value_2 = row_2[fields[which || 1]]
              if value_1 == value_2
                values << value_1
              else
                values = nil
                break
              end
            end
            values
          end

          def create_group(resource_id, row, which)
            group_id = get_next_group_id
            group_row = [group_id, resource_id]
            @group_value_fields.each do |fields|
              group_row.push(row[fields[which || 0]])
            end
            @groups_buffer.add(group_row)
            group_id
          end

          def get_next_group_id
            @mutex.synchronize { @group_number += 1 }
          end
      end
    end
  end
end

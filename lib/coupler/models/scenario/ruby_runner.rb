module Coupler
  module Models
    class Scenario
      class RubyRunner
        LIMIT = 10000

        def initialize(parent)
          @parent = parent
          @resources = parent.resources
          @matcher = parent.matcher
          @type = parent.linkage_type
          @run_number = @parent.run_count + 1
          @mutex = Mutex.new
          @group_number = 0
          setup_pairs
          create_tables
        end

        def run!
          @parent.local_database do |db|
            @groups_dataset = db[@groups_table_name]
            @groups_buffer = ImportBuffer.new(@groups_column_names, @groups_dataset)
            @join_dataset = db[@join_table_name]
            @join_buffer = ImportBuffer.new([:record_id, :resource_id, :group_id], @join_dataset)

            # Group records for each dataset.  This step is the same for both
            # self-linkage and dual-linkage.  However, this is the only step
            # for self-linkage.  Dual-linkage requires another pass after
            # this.
            @pairs = @phase_one_pairs
            tw = ThreadsWait.new
            databases_to_close = []
            @resources.each_with_index do |resource, i|
              dataset = resource.final_dataset
              databases_to_close << dataset.db
              primary_key = resource.primary_key_sym
              which = @type == 'self-linkage' ? nil : i

              resource_thread = new_group_thread(dataset, primary_key, resource.id, which)
              resource_thread.abort_on_exception = true
              tw.join_nowait(resource_thread)
            end
            tw.all_waits
            databases_to_close.each do |db|   # tidy up
              db.disconnect
              ::Sequel::DATABASES.delete(db)
            end

            if @type == 'dual-linkage'
              # Phase 2!
              @pairs = @phase_two_pairs
            end
          end
        end

        private
          def setup_pairs
            @field_pairs = []
            @phase_one_pairs = []
            @phase_two_pairs = []
            @matcher.comparisons.each do |comparison|
              if !comparison.blocking?
                fields = comparison.fields
                @field_pairs << fields
                @phase_one_pairs.push(fields.collect(&:name_sym))
                @phase_two_pairs.push(fields.collect { |f| :"field_#{f.id}" })
              end
            end
          end

          def create_tables
            # Yes, this could be done during setup_pairs, but I think
            # this is more clean.  Also, there will only be very few pairs.
            groups_columns = [
              {:name => :id, :type => Integer, :primary_key => true}
            ]
            @group_value_fields = []
            @field_pairs.each do |(field_1, field_2)|
              @group_value_fields << {:name => field_1.name_sym, :which => 0}
              groups_columns.push(field_1.local_column_options.merge(:name => :"field_#{field_1.id}"))
              if field_1.id != field_2.id
                @group_value_fields << {:name => field_2.name_sym, :which => 1}
                groups_columns.push(field_2.local_column_options.merge(:name => :"field_#{field_2.id}"))
              end
            end
            @groups_column_names = groups_columns.collect { |c| c[:name] }
            @groups_table_name = :"groups_#{@run_number}"

            key_types = @resources.collect { |r| r.primary_key_type }.uniq
            record_id_type = key_types.length == 1 ? key_types[0] : String
            @join_table_name = :"groups_records_#{@run_number}"

            @parent.local_database do |db|
              db.create_table!(@groups_table_name) do
                columns.push(*groups_columns)
              end
              db.create_table!(@join_table_name) do
                column :record_id, record_id_type
                Integer :resource_id
                Integer :group_id, :index => true
              end
            end
          end

          def new_group_thread(dataset, primary_key, resource_id, which)
            Thread.new do
              # Apply filters and what not from comparisons
              dataset = dataset.select(primary_key)
              @matcher.comparisons.each do |comparison|
                dataset = comparison.apply(dataset, which)
              end
              dataset = dataset.order_more(primary_key)

              # Do the work
              threads = process_dataset(dataset, primary_key, resource_id, which)

              @groups_buffer.flush
              @join_buffer.flush

              # Compare heads and tails from segments
              if threads.length > 1
                head = tail = nil
                threads.each_with_index do |thread, j|
                  if j > 0
                    head = thread[:head]
                    if rows_equal?(tail, head, which)
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
          end

          def process_dataset(dataset, primary_key, resource_id, which)
            local_tw = ThreadsWait.new
            threads = []
            count = dataset.count
            segments = count / LIMIT
            segments += 1  if count % LIMIT > 0

            segments.times do |segment_num|
              ds = dataset.limit(LIMIT, LIMIT * segment_num)
              thread = Thread.new do
                row      = nil
                prev_row = nil
                group_id = nil

                ds.each_with_index do |row, row_num|
                  if row_num > 0
                    result = rows_equal?(prev_row, row, which)
                    if (result || which) && group_id.nil?
                      # If `which` is not nil, that means we're in the first
                      # stage of a dual-linkage.  So, we should save groups
                      # that only have 1 record in them.
                      group_id = create_group(prev_row, which)
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
                  group_id = create_group(prev_row, which)
                  @join_buffer.add([prev_row[primary_key], resource_id, group_id])
                end

                # This stores the last record of this segment in order to
                # check it against the first record of the next segment.
                if segment_num < (segments - 1)
                  Thread.current[:tail] = { :row => row, :group_id => group_id }
                end
              end
              thread.abort_on_exception = true
              threads << thread
              local_tw.join_nowait(thread)
              local_tw.next_wait    if local_tw.threads.length == 10
            end
            local_tw.all_waits

            # Return threads for further processing
            threads
          end

          def rows_equal?(row_1, row_2, which)
            #@mutex.synchronize { p [row_1, row_2] }
            @pairs.all? do |fields|
              row_1[fields[which || 0]] == row_2[fields[which || 1]]
            end
          end

          def create_group(row, which)
            group_id = get_next_group_id
            group_row = [group_id]
            @group_value_fields.each do |hash|
              if which.nil? || hash[:which] == which
                group_row.push(row[hash[:name]])
              else
                group_row.push(nil)
              end
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

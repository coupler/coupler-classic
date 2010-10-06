module Coupler
  module Models
    class Scenario
      class GroupWorker
        attr_reader :head, :tail

        def initialize(dataset, record_matcher, save_head = true, save_tail = true)
          @dataset = dataset
          @record_matcher = record_matcher
          @save_head = save_head
          @save_tail = save_tail
        end

        def run
          thread = _run
          thread.abort_on_exception = true
          thread
        end

        private
          def _run
            Thread.new do
              row      = nil
              prev_row = nil
              group_id = nil

              @dataset.each_with_index do |row, row_num|
                if row_num > 0
                  group_id = @record_matcher.compare_and_save(prev_row, row, group_id)

                  # This stores the first record of this segment in order
                  # to check it against the last record of the previous
                  # segment.  I don't like putting this inside the loop
                  # really, but it's better than making another database
                  # query.
                  if @save_head && row_num == 1
                    @head = { :row => prev_row, :group_id => group_id }
                  end
                end
                prev_row = row
              end

              # This stores the last record of this segment in order to
              # check it against the first record of the next segment.
              if @save_tail
                @tail = { :row => row, :group_id => group_id }
              end
            end
          end
      end
    end
  end
end


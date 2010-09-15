module Coupler
  module Models
    class Scenario
      class RubyRunner
        LIMIT = 10000

        def initialize(parent)
          @parent = parent
        end

        def run(score_set)
          threads = []
          resource = @parent.resource_1
          matchers = @parent.matchers
          primary_key = resource.primary_key_name.to_sym
          buffer = RowBuffer.new([:first_id, :second_id, :score, :matcher_id, :transitive], score_set)

          matchers.each do |matcher|
            matcher_id  = matcher.id
            comparisons = matcher.comparisons
            resource.final_dataset do |f_ds|
              f_ds = f_ds.select(primary_key)

              pairs = []
              comparisons.each do |comparison|
                f_ds = comparison.apply(f_ds)
                if !comparison.blocking?
                  pairs << comparison.fields.collect { |f| f.name.to_sym }
                end
              end

              count = f_ds.count
              segments = count / LIMIT
              segments += 1  if count % LIMIT > 0

              tw = ThreadsWait.new
              threads.clear
              segments.times do |i|
                thr = Thread.new(f_ds, i) do |ds, segment_num|
                  id       = nil
                  row      = nil
                  prev_id  = nil
                  prev_row = nil
                  limit    = LIMIT
                  offset   = LIMIT * segment_num

                  ds.limit(limit, offset).each_with_index do |row, row_num|
                    id = row.delete(primary_key)

                    # This stores the first record of this segment in order to
                    # check it against the last record of the previous segment.
                    # I don't like putting this inside the loop really, but
                    # it's better than making another query of limit 1.
                    if segment_num > 0 && row_num == 0
                      Thread.current[:head] = {:id => id, :row => row}
                    end

                    if row_num > 0 && match?(pairs, prev_row, row)
                      buffer.add([prev_id, id, 100, matcher_id, true])
                    else
                      prev_id  = id
                      prev_row = row
                    end
                  end

                  # This stores the last record of this segment in order to
                  # check it against the first record of the next segment.
                  if segment_num < (segments - 1)
                    Thread.current[:tail] = {:id => id, :row => row}
                  end
                end
                thr.abort_on_exception = true
                threads << thr
                tw.join_nowait(thr)
                tw.next_wait    if tw.threads.length == 10
              end
              tw.all_waits

              # Compare heads and tails from segments
              if segments > 1
                head = tail = nil
                len = threads.length
                threads.each_with_index do |thr, i|
                  if i > 0
                    head = thr[:head]
                    if match?(pairs, tail[:row], head[:row])
                      buffer.add([tail[:id], head[:id], 100, matcher_id, true])
                    end
                  end
                  tail = thr[:tail] if i < (len - 1)
                end
              end
              buffer.flush
            end
          end
        end

        def match?(pairs, row_1, row_2)
          pairs.all? do |(field_1, field_2)|
            row_1[field_1] == row_2[field_2]
          end
        end
      end
    end
  end
end

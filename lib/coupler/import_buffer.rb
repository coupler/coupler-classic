module Coupler
  # This class is used during resource transformation.  Its purpose
  # is for mass inserts into the local database for speed.
  class ImportBuffer
    MAX_QUERY_SIZE = 1_048_576

    attr_writer :dataset

    def initialize(columns, dataset, &progress)
      @columns = columns
      @dataset = dataset
      @mutex = Mutex.new
      @progress = progress
      @pending = 0
    end

    def add(row)
      fragment = " " + @dataset.literal(row.is_a?(Hash) ? row.values_at(*@columns) : row) + ","
      @mutex.synchronize do
        init_query  if @query.nil?
        if (@query.length + fragment.length) > MAX_QUERY_SIZE
          flush(false)
          init_query
        end
        @query << fragment
        @pending += 1
      end
    end

    def flush(lock = true)
      begin
        @mutex.lock   if lock
        if @query
          @dataset.db.run(@query.chomp(","))
          @progress.call(@pending) if @progress
          @pending = 0
          @query = nil
        end
      ensure
        @mutex.unlock if lock
      end
    end

    private
      def init_query
        @query = String.alloc(MAX_QUERY_SIZE)
        @query << @dataset.insert_sql(@columns, Sequel::LiteralString.new('VALUES'))
      end
  end
end

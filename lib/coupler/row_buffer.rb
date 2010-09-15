module Coupler
  # This class is used during resource transformation.  Its purpose
  # is for mass inserts into the local database for speed.
  class RowBuffer
    attr_writer :dataset
    def initialize(columns, dataset, &progress)
      @columns = columns
      @dataset = dataset
      @mutex = Mutex.new
      @progress = progress
      @pending = 0

      # Subtracting 4 at the end accounts for the query packet header (I think)
      @max_allowed_packet = dataset.
        db["SHOW VARIABLES LIKE ?", 'max_allowed_packet'].
        first[:Value].to_i - 4

      init_query
    end

    def add(row)
      fragment = " " + @dataset.literal(row.is_a?(Hash) ? row.values_at(*@columns) : row) + ","
      @mutex.synchronize do
        if (@query.length + fragment.length) > @max_allowed_packet
          flush
          init_query
        end
        @query << fragment
        @pending += 1
      end
    end

    def flush
      if @query
        @dataset.db.run(@query.chomp(","))
        @progress.call(@pending) if @progress
        @pending = 0
        @query = nil
      end
    end

    private
      def init_query
        @query = String.alloc(@max_allowed_packet)
        @query << @dataset.insert_sql(@columns, Sequel::LiteralString.new('VALUES'))
      end
  end
end

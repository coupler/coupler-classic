module Coupler
  module Models
    class Resource
      class Runner
        attr_reader :fields
        def initialize(parent)
          @parent = parent
          @thread_pool = ThreadPool.new(10)
          @mutex = Mutex.new
          @fields = @parent.selected_fields_dataset.order(:id).all
          @transformations = @parent.transformations
          create_local_table
        end

        def create_local_table
          cols = @fields.collect { |f| f.local_column_options }
          @parent.local_database do |l_db|
            # create intermediate table
            l_db.create_table!(@parent.slug) do
              columns.push(*cols)
            end
          end
        end

        def add_row(dataset, rows, row)
          @mutex.synchronize do
            rows.push(row)
            if rows.length == 1000
              flush_rows(dataset, rows)
            end
          end
        end

        def flush_rows(dataset, rows)
          dataset.multi_insert(rows)
          rows.clear
        end

        def transform
          @parent.local_database do |l_db|
            l_ds = l_db[@parent.slug.to_sym]

            @parent.source_dataset do |s_ds|
              rows = []
              s_ds.each do |row|
                @thread_pool.execute(row) do |r|
                  hash = @transformations.inject(row) { |x, t| t.transform(x) }
                  add_row(l_ds, rows, hash)
                  #self.class.filter(:id => self.id).update("completed = completed + 1")
                end
              end
              @thread_pool.join
              flush_rows(l_ds, rows)
            end
          end
        end
      end
    end
  end
end

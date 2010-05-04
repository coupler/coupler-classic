module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      include Jobify

      many_to_one :project
      one_to_many :transformations
      one_to_many :fields

      plugin :nested_attributes
      nested_attributes(:fields, :destroy => false, :fields => [:is_selected]) { |h| !(h.has_key?('id') || h.has_key?(:id)) }

      def source_database(&block)
        Sequel.connect(source_connection_string, {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      def source_dataset
        source_database do |db|
          ds = db[table_name.to_sym]
          if fields_dataset.filter(:is_selected => 0).count > 0
            columns = fields_dataset.filter(:is_selected => 1).collect(&:name)
            ds = ds.select(*columns.collect(&:to_sym))
          end
          yield ds
        end
      end

      def source_schema
        schema = nil
        source_database { |db| schema = db.schema(table_name) }
        schema
      end

      def local_database(&block)
        Sequel.connect(local_connection_string, {
          :loggers => [Coupler::Logger.instance],
        }, &block)
      end

      def local_dataset
        local_database do |database|
          ds = database[self.slug.to_sym]
          yield ds
        end
      end

      def final_database(&block)
        if transformations_dataset.count == 0
          source_database(&block)
        else
          local_database(&block)
        end
      end

      def final_dataset(&block)
        if transformations_dataset.count == 0
          source_dataset(&block)
        else
          local_dataset(&block)
        end
      end

      def status
        if transformed_at.nil?
          if transformations_dataset.count > 0
            "out_of_date"
          else
            "ok"
          end
        else
          if transformations_dataset.filter("updated_at > ?", self.transformed_at).count > 0
            "out_of_date"
          else
            "ok"
          end
        end
      end

      def scenarios
        Scenario.filter(["resource_1_id = ? OR resource_2_id = ?", id, id]).all
      end

      def update_fields
        transformations_dataset.order(:id).each do |transformation|
          field = transformation.field
          changes = transformation.field_changes[field.id]
          field.local_db_type = changes[:db_type] || field[:db_type]
          field.local_type = changes[:type] || field[:type]
          field.save
        end
      end

      def transform!
        fields_ds = fields_dataset.filter(:is_selected => 1).order(:id)
        local_database do |l_db|
          # create intermediate table
          l_db.create_table!(self.slug) do
            fields_ds.each { |f| columns << f.local_column_options }
          end

          l_ds = l_db[self.slug.to_sym]

          source_dataset do |s_ds|
            # for progress bar
            #self.update(:total => s_ds.count, :completed => 0)

            thread_pool = ThreadPool.new(10)
            s_ds.each do |row|
              thread_pool.execute(row) do |r|
                hash = transformations.inject(r) { |x, t| t.transform(x) }
                l_ds.insert(hash)
                #self.class.filter(:id => self.id).update("completed = completed + 1")
              end
            end
            thread_pool.join

            self.update(:transformed_at => Time.now)
          end
        end
      end

      private
        def source_connection_string
          misc = adapter == 'mysql' ? '&zeroDateTimeBehavior=convertToNull' : ''
          "jdbc:%s://%s:%d/%s?user=%s&password=%s%s" % [
            adapter, host, port, database_name, username, password, misc
          ]
        end

        def local_connection_string
          Config.connection_string(self.project.slug, {
            :create_database => true,
            :zero_date_time_behavior => :convert_to_null
          })
        end

        def create_fields
          source_schema.each do |(name, info)|
            Field.create({
              :name => name,
              :type => info[:type],
              :db_type => info[:db_type],
              :is_primary_key => info[:primary_key] ? 1 : 0,
              :resource_id => self.id
            })
          end
        end

        def validate
          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            if self.new?
              count = self.class.filter(:name => self.name).count
              errors[:name] << "is already taken"   if count > 0
            else
              count = self.class.filter(["name = ? AND id != ?", self.name, self.id]).count
              errors[:name] << "is already taken"   if count > 0
            end
          end

          if self.new?
            count = self.class.filter(:slug => self.slug).count
            errors[:slug] << "is already taken"   if count > 0
          else
            count = self.class.filter(["slug = ? AND id != ?", self.slug, self.id]).count
            errors[:slug] << "is already taken"   if count > 0
          end

          try_connect = true
          [:database_name, :table_name].each do |name|
            value = self.send(name)
            if value.nil? || value == ""
              try_connect = false
              errors[name] << "is required"
            end
          end

          if try_connect
            begin
              source_database do |db|
                db.test_connection
                sym = self.table_name.to_sym
                if !db.tables.include?(sym)
                  errors[:table_name] << "is invalid"
                end

                keys = db.schema(sym).select { |info| info[1][:primary_key] }
                if keys.empty?
                  errors[:table_name] << "doesn't have a primary key"
                elsif keys.length > 1
                  errors[:table_name] << "has too many primary keys"
                elsif keys[0][1][:type] != :integer
                  errors[:table_name] << "has non-integer primary key"
                end
              end
            rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
              errors[:base] << "Couldn't connect to the database"
            end
          end
        end

        def before_save
          if new?
            # NOTE: I'm doing this instead of using before_create because
            # serialization happens in before_save, which gets called before
            # the before_create hook
            self.slug ||= self.name.downcase.gsub(/\s+/, "_")
            source_database do |db|
              schema = db.schema(self.table_name)
              self.primary_key_name = schema.detect { |x| x[1][:primary_key] }[0].to_s
            end
          end
          super
        end

        def after_create
          super
          create_fields
        end
    end
  end
end

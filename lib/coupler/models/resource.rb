module Coupler
  module Models
    class Resource < Sequel::Model
      include CommonModel
      include Jobify

      many_to_one :connection
      many_to_one :project
      many_to_one :import
      one_to_many :transformations
      one_to_many :fields
      one_to_many :selected_fields, {
        :class => 'Coupler::Models::Field', :key => 'resource_id',
        :conditions => {:is_selected => 1}, :read_only => true
      }

      plugin :nested_attributes
      nested_attributes(:fields, :destroy => false, :fields => [:is_selected]) { |h| !(h.has_key?('id') || h.has_key?(:id)) }

      def source_database(&block)
        if import
          project.local_database(&block)
        else
          connection.database(database_name, &block)
        end
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

      def local_dataset
        project.local_database do |database|
          ds = database[:"resource_#{id}"]
          yield ds
        end
      end

      def final_database(&block)
        if transformations_dataset.count == 0
          source_database(&block)
        else
          project.local_database(&block)
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
        transformations_dataset.order(:position).each do |transformation|
          if transformation.source_field_id == transformation.result_field_id
            source_field = transformation.source_field
            changes = transformation.field_changes[source_field.id]
            source_field.local_db_type = changes[:db_type] || source_field[:db_type]
            source_field.local_type = changes[:type] || source_field[:type]
            source_field.save
          end
        end
      end

      def transform!
        runner = Runner.new(self)
        runner.transform
        self.update(:transformed_at => Time.now)
      end

      private
        def local_connection_string
          Config.connection_string(:"project_#{project.id}", {
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

        def before_validation
          super

          if import
            self.project = import.project
            self.name = import.name
            self.table_name = "import_#{import.id}"
            self.database_name = "project_#{import.project.id}"
          end
        end

        def validate
          super

          if project.nil?
            errors[:project_id] << "is required"
          end

          if self.name.nil? || self.name == ""
            errors[:name] << "is required"
          else
            if self.new?
              count = self.class.filter(:name => name, :project_id => project_id).count
              errors[:name] << "is already taken"   if count > 0
            else
              count = self.class.filter({:name => name, :project_id => project_id}, ~{:id => id}).count
              errors[:name] << "is already taken"   if count > 0
            end
          end

          if self.new?
            count = self.class.filter(:slug => slug, :project_id => project_id).count
            errors[:slug] << "is already taken"   if count > 0
          else
            count = self.class.filter({:slug => slug, :project_id => project_id}, ~{:id => id}).count
            errors[:slug] << "is already taken"   if count > 0
          end

          if import.nil?
            if database_name.nil? || database_name == ""
              errors[:database_name] << "is required"
            else
              begin
                connection.database(database_name) { |db| db.test_connection }
              rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
                errors[:database_name] << "is not valid"
              end
            end

            if table_name.nil? || table_name == ""
              errors[:table_name] << "is required"
            elsif !errors.has_key?(:database_name)
              #begin
                source_database do |db|
                  sym = self.table_name.to_sym
                  if !db.tables.include?(sym)
                    errors[:table_name] << "is invalid"
                  else
                    keys = db.schema(sym).select { |info| info[1][:primary_key] }
                    if keys.empty?
                      errors[:table_name] << "doesn't have a primary key"
                    elsif keys.length > 1
                      errors[:table_name] << "has too many primary keys"
                    end
                  end
                end
              #rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
                #errors[:base] << "Couldn't connect to the database"
              #end
            end
          end
        end

        def before_save
          if new?
            # NOTE: I'm doing this instead of using before_create because
            # serialization happens in before_save, which gets called before
            # the before_create hook
            if import
              self.name = import.name
              self.project = import.project
              import.import!
            end
            self.slug ||= self.name.downcase.gsub(/\s+/, "_")
            source_database do |db|
              schema = db.schema(self.table_name)
              info = schema.detect { |x| x[1][:primary_key] }
              self.primary_key_name = info[0].to_s
              self.primary_key_type = info[1][:type].to_s
            end
          end
          super
        end

        def after_create
          super
          create_fields
        end

        def after_destroy
          super
          if transformations_dataset.count > 0 && !transformed_at.nil?
            project.local_database do |db|
              db.drop_table(:"resource_#{id}")
            end
          end
          fields_dataset.each { |f| f.delete_versions_on_destroy = self.delete_versions_on_destroy; f.destroy }
          transformations_dataset.each { |t| t.delete_versions_on_destroy = self.delete_versions_on_destroy; t.destroy }
        end
    end
  end
end

require File.join(File.dirname(__FILE__), 'resource', 'runner')

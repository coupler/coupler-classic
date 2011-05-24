module Coupler
  module Models
    class Resource < Sequel::Model
      LIMIT = 10000

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
      nested_attributes(:connection, :destroy => false)
      nested_attributes(:fields, :destroy => false, :fields => [:is_selected]) { |h| !(h.has_key?('id') || h.has_key?(:id)) }

      attr_accessor :resource_type

      def self.count_by_project
        dataset.naked.group_and_count(:project_id).to_hash(:project_id, :count)
      end

      def import=(*args)
        result = super
        if new?
          self.project = import.project
          n = 1
          name = import.name
          loop do
            ds = Resource.filter(:name => name, :project_id => import.project_id)
            if ds.count > 0
              n += 1
              name = "#{import.name} #{n}"
            else
              break
            end
          end
          self.name = name
          self.table_name = "import_#{import.id}"
        end
        result
      end

      def name=(*args)
        result = super
        if new?
          self.slug ||= name.downcase.gsub(/\s+/, "_")
        end
        result
      end

      def source_database(&block)
        if import
          project.local_database(&block)
        else
          connection.database(&block)
        end
      end

      def source_dataset
        if block_given?
          source_database do |database|
            columns = fields_dataset.filter(:is_selected => true, :is_generated => false).collect { |f| f.name.to_sym }
            yield database[table_name.to_sym].select(*columns.collect(&:to_sym))
          end
        else
          database = source_database
          columns = fields_dataset.filter(:is_selected => true, :is_generated => false).collect { |f| f.name.to_sym }
          database[table_name.to_sym].select(*columns.collect(&:to_sym))
        end
      end

      def source_dataset_count
        count = nil
        source_dataset { |ds| count = ds.count }
        count
      end

      def source_schema
        schema = nil
        source_database { |db| schema = db.schema(table_name.to_sym) }
        schema
      end

      def local_dataset
        if block_given?
          project.local_database do |database|
            ds = database[:"resource_#{id}"]
            yield ds
          end
        else
          database = project.local_database
          database[:"resource_#{id}"]
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
        if transformed_with.to_s != transformation_ids.join(",") || transformations_dataset.filter("updated_at > ?", transformed_at).count > 0
          "out_of_date"
        else
          "ok"
        end
      end

      def scenarios
        Scenario.filter(["resource_1_id = ? OR resource_2_id = ?", id, id]).all
      end

      def refresh_fields!
        fields_dataset.update(:local_db_type => nil, :local_type => nil)
        transformations_dataset.order(:position).each do |transformation|
          if transformation.source_field_id == transformation.result_field_id
            source_field = transformation.source_field
            changes = transformation.field_changes[source_field.id]
            source_field.update({
              :local_db_type => changes[:db_type] || source_field[:db_type],
              :local_type    => changes[:type]    || source_field[:type]
            })
          end
        end
      end

      def transform!(&progress)
        t_ids = transformation_ids.join(",")
        create_local_table!
        _transform(&progress)
        self.update({
          :transformed_at => Time.now,
          :transformed_with => t_ids
        })
      end

      def preview_transformation(transformation)
        result = []
        _iterate_over_source_and_transform(50) { |r| result << r }
        result.each_index do |i|
          begin
            after = transformation.transform(result[i].dup)
            result[i] = { :before => result[i], :after => after }
          rescue Exception => e # yes, I know rescuing Exception is "bad"
            return e
          end
        end
        fields = result[0][:before].keys | result[0][:after].keys
        { :fields => fields, :data => result }
      end

      def primary_key_sym
        primary_key_name.to_sym
      end

      private
        def transformation_ids
          transformations_dataset.select(:id).order(:id).all.collect(&:id)
        end

        def local_connection_string
          Coupler.connection_string("project_#{project.id}")
        end

        def create_fields
          source_schema.each do |(name, info)|
            add_field({
              :name => name,
              :type => info[:type],
              :db_type => info[:db_type],
              :is_primary_key => info[:primary_key]
            })
          end
        end

        def create_local_table!
          fields = selected_fields_dataset.order(:id).all
          cols = fields.collect { |f| f.local_column_options }
          project.local_database do |l_db|
            # create intermediate table
            l_db.create_table!("resource_#{id}") do
              columns.push(*cols)
            end
          end
        end

        def _transform(&progress)
          local_dataset do |l_ds|
            field_names = selected_fields_dataset.order(:id).naked.select(:name).map { |r| r[:name].to_sym }
            buffer = ImportBuffer.new(field_names, l_ds, &progress)
            _iterate_over_source_and_transform { |r| buffer.add(r) }
            buffer.flush
          end
        end

        def _iterate_over_source_and_transform(total = nil)
          tw = ThreadsWait.new
          transformations = transformations_dataset.order(:position).all
          source_dataset do |s_ds|
            total ||= s_ds.count
            limit   = (total && total < LIMIT) ? total : LIMIT
            offset  = 0
            count   = 0
            while count < total
              s_ds = s_ds.limit(limit, offset)
              offset += limit
              count  += limit

              thr = Thread.new(s_ds) do |ds|
                ds.each do |row|
                  hash = transformations.inject(row) { |x, t| t.transform(x) }
                  yield hash
                end
              end
              thr.abort_on_exception = true
              tw.join_nowait(thr)
              tw.next_wait    if tw.threads.length == 10
            end
            tw.all_waits
          end
        end

        def validate
          super
          validates_presence [:project_id, :name]
          validates_presence :slug
          validates_unique [:name, :project_id], [:slug, :project_id]
          validates_presence [:table_name]

          if import.nil? && errors.on(:table_name).nil?
            source_database do |db|
              sym = self.table_name.to_sym
              if !db.tables.include?(sym)
                errors.add(:table_name, "is invalid")
              else
                keys = db.schema(sym).select { |info| info[1][:primary_key] }
                if keys.empty?
                  errors.add(:table_name, "doesn't have a primary key")
                elsif keys.length > 1
                  errors.add(:table_name, "has too many primary keys")
                end
              end
            end
          end
        end

        def before_save
          if new?
            # NOTE: I'm doing this instead of using before_create because
            # serialization happens in before_save, which gets called before
            # the before_create hook
            source_database do |db|
              schema = db.schema(table_name.to_sym)
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
          tds = transformations_dataset
          if tds.count > 0 && !transformed_at.nil?
            project.local_database do |db|
              db.drop_table(:"resource_#{id}")
            end
          end
          fields_dataset.each { |f| f.delete_versions_on_destroy = self.delete_versions_on_destroy; f.destroy }
          tds.each { |t| t.delete_versions_on_destroy = self.delete_versions_on_destroy; t.destroy }
        end
    end
  end
end

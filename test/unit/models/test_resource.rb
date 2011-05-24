require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestResource < Coupler::Test::UnitTest
      def setup
        super
        @local_database = stub('project database')
        @project = stub_project
        @project.stubs(:local_database).yields(@local_database)

        @source_database = stub('source database', {
          :tables => [:foo],
          :schema => [
            [:id,  {:primary_key => true,  :type => :integer, :db_type => "BIGINT"}],
            [:foo, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}],
            [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
          ]
        })
        @connection = stub('connection', :pk => 456, :id => 456, :associations => {})
        @connection.stubs(:database).yields(@source_database)
      end

      def new_resource(attribs = {})
        values = {
          :name => 'Foo bar',
          :table_name => 'foo',
          :project => @project,
          :connection => @connection
        }.update(attribs)
        r = Resource.new(values)
        r.stubs(:project_dataset).returns(stub({:all => [values[:project]]}))
        r.stubs(:connection_dataset).returns(stub({:all => [values[:connection]]}))
        r
      end

      def stub_project(id = 123, methods = {})
        stub('project', {:pk => id, :id => id, :associations => {}}.update(methods))
      end

      test "sequel model" do
        assert_equal Sequel::Model, Resource.superclass
        assert_equal :resources, Resource.table_name
      end

      test "many to one connection" do
        assert_respond_to Resource.new, :connection
      end

      test "many to one project" do
        assert_respond_to Resource.new, :project
      end

      test "one to many transformations" do
        assert_respond_to Resource.new, :transformations
      end

      test "one to many jobs" do
        assert_respond_to Resource.new, :jobs
      end

      test "one to many fields" do
        assert_respond_to Resource.new, :fields
      end

      test "one to many selected fields" do
        assert_respond_to Resource.new, :selected_fields
      end

      test "many to one import" do
        assert_respond_to Resource.new, :import
      end

      test "one to many running_jobs" do
        assert_respond_to Resource.new, :running_jobs
      end

      test "one to many scheduled_jobs" do
        assert_respond_to Resource.new, :scheduled_jobs
      end

      test "jobified" do
        assert Resource.ancestors.include?(Jobify)
      end

      test "nested attributes for connection" do
        assert_respond_to Resource.new, :connection_attributes=
      end

      #test "invalid nested attributes for connection" do
        #connection_count = Connection.count
        #resource_count = Resource.count

        #resource = Factory.build(:resource, :connection => nil)
        #resource.connection_attributes = Factory.attributes_for(:connection, :name => nil, :host => nil)
        #resource.save

        #assert_equal resource_count, Resource.count
        #assert_equal connection_count, Connection.count
      #end

      test "nested attributes for fields" do
        assert_respond_to Resource.new, :fields_attributes=
      end

      test "rejects new fields for nested attributes" do
        resource = new_resource
        resource.save!
        resource.fields_attributes = [{:is_selected => 0}]
        resource.expects(:add_field).times(0)
        resource.save!
      end

      test "requires project" do
        resource = new_resource
        args = []
        resource.expects(:validates_presence).at_least(1).with { |*a| args << a; true }
        resource.save
        args.flatten!
        assert args.include?(:project_id)
      end

      test "requires name" do
        resource = new_resource
        args = []
        resource.expects(:validates_presence).at_least(1).with { |*a| args << a; true }
        resource.save
        args.flatten!
        assert args.include?(:name)
      end

      test "requires unique name across projects" do
        resource = new_resource
        resource.expects(:validates_unique).with do |*args|
          args.include?([:name, :project_id])
        end
        resource.save
      end

      test "requires non empty table_name" do
        resource = new_resource
        args = []
        resource.expects(:validates_presence).at_least(1).with { |*a| args << a; true }
        resource.save
        args.flatten!
        assert args.include?(:table_name)
      end

      test "requires valid table_name" do
        @source_database.stubs(:tables).returns([])
        resource = new_resource
        assert !resource.valid?, "Resource wasn't invalid"
      end

      test "sets slug from name" do
        resource = new_resource(:name => 'Foo bar')
        assert_equal "foo_bar", resource.slug
      end

      test "requires unique slug across projects" do
        resource = new_resource
        resource.expects(:validates_unique).with do |*args|
          args.include?([:slug, :project_id])
        end
        resource.save
      end

      test "requires table with primary key" do
        @source_database.stubs(:schema).returns([
          [:id,  {:primary_key => false,  :type => :integer, :db_type => "BIGINT"}],
          [:foo, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}],
          [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
        ])
        resource = new_resource
        assert !resource.valid?
      end

      test "requires single primary key" do
        @source_database.stubs(:schema).returns([
          [:id,  {:primary_key => true, :type => :integer, :db_type => "BIGINT"}],
          [:foo, {:primary_key => true, :type => :string, :db_type => "VARCHAR"}],
          [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
        ])
        resource = new_resource
        assert !resource.valid?
      end

      test "does not requires integer primary key" do
        @source_database.stubs(:schema).returns([
          [:id,  {:primary_key => false, :type => :integer, :db_type => "BIGINT"}],
          [:foo, {:primary_key => true, :type => :string, :db_type => "VARCHAR"}],
          [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
        ])
        resource = new_resource
        assert resource.valid?
      end

      test "sets primary_key_name" do
        @source_database.stubs(:schema).returns([
          [:my_id,  {:primary_key => true, :type => :integer, :db_type => "BIGINT"}],
          [:foo, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}],
          [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
        ])
        resource = new_resource.save!
        assert_equal 'my_id', resource.primary_key_name
      end

      test "sets primary_key_type" do
        @source_database.stubs(:schema).returns([
          [:my_id,  {:primary_key => true, :type => :integer, :db_type => "BIGINT"}],
          [:foo, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}],
          [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
        ])
        resource = new_resource.save!
        assert_equal 'integer', resource.primary_key_type
      end

      test "creates fields" do
        @source_database.stubs(:schema).returns([
          [:id, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"int(11)", :type=>:integer, :ruby_default=>nil}],
          [:first_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}],
          [:last_name, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :type=>:string, :ruby_default=>nil}]
        ])

        resource = new_resource
        resource.expects(:add_field).with do |h|
          h[:name] == :id && h[:type] == :integer &&
            h[:db_type] == 'int(11)' && h[:is_primary_key]
        end
        resource.expects(:add_field).with do |h|
          h[:name] == :first_name && h[:type] == :string &&
            h[:db_type] == 'varchar(255)' && !h[:is_primary_key]
        end
        resource.expects(:add_field).with do |h|
          h[:name] == :last_name && h[:type] == :string &&
            h[:db_type] == 'varchar(255)' && !h[:is_primary_key]
        end
        resource.save!
      end

      test "source_database with block" do
        resource = new_resource.save!
        @connection.expects(:database).yields(@source_database)
        resource.source_database do |db|
          assert_equal @source_database, db
        end
      end

      test "source_database without block" do
        resource = new_resource.save!
        @connection.expects(:database).returns(@source_database)
        assert_equal @source_database, resource.source_database
      end

      test "source_dataset" do
        resource = new_resource.save!

        # ghetto mock!
        fd = [stub(:name => 'id'), stub(:name => 'foo'), stub(:name => 'bar')]
        fd.expects(:filter).with(:is_selected => true, :is_generated => false).returns(fd)
        resource.stubs(:fields_dataset).returns(fd)

        dataset = mock('dataset')
        dataset.expects(:select).with(:id, :foo, :bar).returns(dataset)
        @source_database.expects(:[]).with(:foo).returns(dataset)

        # with block
        resource.source_dataset do |rdataset|
          assert_equal dataset, rdataset
        end
      end

      test "source_dataset without block" do
        resource = new_resource.save!

        # ghetto mock!
        fd = [stub(:name => 'id'), stub(:name => 'foo'), stub(:name => 'bar')]
        fd.expects(:filter).with(:is_selected => true, :is_generated => false).returns(fd)
        resource.stubs(:fields_dataset).returns(fd)

        dataset = mock('dataset')
        dataset.expects(:select).with(:id, :foo, :bar).returns(dataset)
        @connection.expects(:database).returns(@source_database)
        @source_database.expects(:[]).with(:foo).returns(dataset)

        assert_equal dataset, resource.source_dataset
      end

      test "source_schema" do
        resource = new_resource.save!
        schema = stub('schema')
        @source_database.expects(:schema).with(:foo).returns(schema)
        assert_equal schema, resource.source_schema
      end

      test "local_dataset" do
        resource = new_resource.save!
        dataset = mock('dataset')
        @local_database.expects(:[]).with(:"resource_#{resource.id}").returns(dataset)
        resource.local_dataset do |ds|
          assert_equal dataset, ds
        end
      end

      test "local dataset without block" do
        resource = new_resource.save!

        @project.expects(:local_database).returns(@local_database)
        dataset = stub('dataset')
        @local_database.expects(:[]).with(:"resource_#{resource.id}").returns(dataset)
        assert_equal dataset, resource.local_dataset
      end

      test "refresh fields" do
        resource = new_resource.save!
        field_1 = stub("id field", :id => 1)
        field_2 = stub("first_name field", :id => 2)
        field_3 = stub("last_name field", :id => 3)

        transformation_1 = stub("transformation 1", {
          :source_field_id => 2, :result_field_id => 2,
          :field_changes => {2 => {:type => :integer, :db_type => 'int(11)'}},
          :source_field => field_2
        })
        transformation_2 = stub("transformation 2", {
          :source_field_id => 3, :result_field_id => 3,
          :field_changes => {3 => {:type => :integer, :db_type => 'int(11)'}},
          :source_field => field_3
        })
        transformation_3 = stub("transformation 3", {
          :source_field_id => 3, :result_field_id => 3,
          :field_changes => {3 => {:type => :datetime, :db_type => 'datetime'}},
          :source_field => field_3
        })

        resource.stubs(:fields_dataset).returns(stub(:update => nil))
        td = [transformation_1, transformation_2, transformation_3]
        td.expects(:order).with(:position).returns(td)
        resource.expects(:transformations_dataset).returns(td)

        seq = sequence("update")
        field_2.expects(:update).with({
          :local_type => :integer, :local_db_type => 'int(11)'
        }).in_sequence(seq)
        field_3.expects(:update).with({
          :local_type => :integer, :local_db_type => 'int(11)'
        }).in_sequence(seq)
        field_3.expects(:update).with({
          :local_type => :datetime, :local_db_type => 'datetime'
        }).in_sequence(seq)

        resource.refresh_fields!
      end

      test "refresh_fields does not change newly created result field" do
        resource = new_resource.save!
        field_1 = stub("id field", :id => 1)
        field_2 = stub("first_name field", :id => 2)
        field_3 = stub("last_name field", :id => 3)
        new_field = stub("new field", :id => 4)

        transformation = stub("transformation 1", {
          :source_field_id => 2, :result_field_id => 4,
          :field_changes => {2 => {:type => :integer, :db_type => 'int(11)'}},
          :source_field => field_2
        })

        resource.stubs(:fields_dataset).returns(stub(:update => nil))
        td = [transformation]
        td.expects(:order).with(:position).returns(td)
        resource.expects(:transformations_dataset).returns(td)

        field_2.expects(:update).never
        new_field.expects(:update).never

        resource.refresh_fields!
      end

      test "refresh_fields resets local_type and local_db_type" do
        resource = new_resource.save!

        resource.expects(:fields_dataset).returns(mock {
          expects(:update).with(:local_type => nil, :local_db_type => nil)
        })
        td = []
        td.expects(:order).with(:position).returns(td)
        resource.expects(:transformations_dataset).returns(td)

        resource.refresh_fields!
      end

      test "initial status" do
        resource = new_resource.save!
        assert_equal "ok", resource.status
      end

      test "status after adding first transformation" do
        resource = new_resource.save!
        resource.stubs(:transformation_ids).returns([1])
        assert_equal "out_of_date", resource.status
      end

      test "status when new transformation is created since transforming" do
        resource = new_resource(:transformed_with => "1").save!
        resource.stubs(:transformation_ids).returns([1,2])
        assert_equal "out_of_date", resource.status
      end

      test "status when transformation is updated since transforming" do
        now = Time.now
        resource = new_resource(:transformed_with => "1", :transformed_at => now - 20).save!
        resource.stubs(:transformation_ids).returns([1])
        resource.stubs(:transformations_dataset).returns(stub {
          stubs(:filter).with('updated_at > ?', now - 20).returns(self)
          stubs(:count).returns(1)
        })
        assert_equal "out_of_date", resource.status
      end

      test "status when transformation is removed since transforming" do
        now = Time.now
        resource = new_resource(:transformed_at => now - 5, :transformed_with => "1").save!
        resource.stubs(:transformation_ids).returns([])
        assert_equal "out_of_date", resource.status
      end

      test "status when new transformation is removed before transforming" do
        resource = new_resource.save!
        resource.stubs(:transformation_ids).returns([1])
        assert_equal "out_of_date", resource.status
        resource.stubs(:transformation_ids).returns([])
        assert_equal "ok", resource.status
      end

      test "final_database is source_database without transformations" do
        resource = new_resource.save!
        resource.stubs(:transformations_dataset).returns(stub(:count => 0))
        db = stub('db')
        resource.expects(:source_database).returns(db)
        assert_equal db, resource.final_database
      end

      test "final_database is local_database with transformations" do
        resource = new_resource.save!
        resource.stubs(:transformations_dataset).returns(stub(:count => 1))
        db = stub('db')
        @project.expects(:local_database).returns(db)
        assert_equal db, resource.final_database
      end

      test "final_dataset is source_dataset without transformations" do
        resource = new_resource.save!
        resource.stubs(:transformations_dataset).returns(stub(:count => 0))
        ds = stub('dataset')
        resource.expects(:source_dataset).returns(ds)
        assert_equal ds, resource.final_dataset
      end

      test "final_dataset is local_dataset with transformations" do
        resource = new_resource.save!
        resource.stubs(:transformations_dataset).returns(stub(:count => 1))
        ds = stub('dataset')
        resource.expects(:local_dataset).returns(ds)
        assert_equal ds, resource.final_dataset
      end

      test "scenarios" do
        resource = new_resource.save!
        scenario = stub('scenario')
        Scenario.expects(:filter).with(['resource_1_id = ? OR resource_2_id = ?', resource.id, resource.id]).returns(stub(:all => [scenario]))
        assert_equal [scenario], resource.scenarios
      end

      test "deletes dependencies after destroy" do
        resource = new_resource.save!

        resource.expects(:fields_dataset).returns([
          mock('field 1', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } },
          mock('field 2', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } },
          mock('field 3', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } }
        ])
        resource.expects(:transformations_dataset).returns([
          mock('transformation 1', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } },
          mock('transformation 2', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } },
          mock('transformation 3', :destroy => nil) { expects(:delete_versions_on_destroy=).with { |arg| !arg } }
        ])
        resource.destroy
      end

      test "deletes local dataset after destroy" do
        resource = new_resource(:transformed_at => Time.now).save!
        resource.expects(:transformations_dataset).returns([stub_everything('transformation')])
        @local_database.expects(:drop_table).with(:"resource_#{resource.id}")
        resource.destroy
      end

      test "forceably deletes versions after destroy" do
        resource = new_resource.save!
        resource.delete_versions_on_destroy = true
        resource.expects(:fields_dataset).returns([
          mock('field 1', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) },
          mock('field 2', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) },
          mock('field 3', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) }
        ])
        resource.expects(:transformations_dataset).returns([
          mock('transformation 1', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) },
          mock('transformation 2', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) },
          mock('transformation 3', :destroy => nil) { expects(:delete_versions_on_destroy=).with(true) }
        ])

        resource.destroy
      end

      test "creating resource via import" do
        import = stub("import", {
          :id => 123, :pk => 123, :project => @project,
          :name => "People", :project_id => @project.id
        })
        resource = Resource.new(:import => import)
        assert_equal "People", resource.name
        assert_equal @project, resource.project
        assert_equal "import_123", resource.table_name
        assert resource.valid?

        # import.import! would happen before saving the resource
        @local_database.stubs({
          :tables => [:import_123],
          :schema => [
            [:id,  {:primary_key => true,  :type => :integer, :db_type => "BIGINT"}],
            [:foo, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}],
            [:bar, {:primary_key => false, :type => :string, :db_type => "VARCHAR"}]
          ]
        })
        resource.save!
        assert_equal "id", resource.primary_key_name
        assert_equal "integer", resource.primary_key_type
      end

      test "creating resource via import with duplicate name" do
        resource_1 = new_resource(:name => "People").save!
        import = stub("import", {
          :id => 123, :pk => 123, :project => @project,
          :name => "People", :project_id => @project.id
        })
        resource = Resource.new(:import => import)
        assert_equal "People 2", resource.name
        assert_equal @project, resource.project
        assert_equal "import_123", resource.table_name
        assert resource.valid?
      end

      test "source_dataset count" do
        resource = new_resource.save!
        dataset = mock('dataset', :count => 12345)
        resource.expects(:source_dataset).yields(dataset)
        assert_equal resource.source_dataset_count, 12345
      end

      #def test_unselecting_a_generated_field_before_transformation
        #pend
      #end

      #def test_connection_limit_on_source_database
        #pend
      #end

      #def test_connection_limit_on_local_database
        #pend
      #end

      test "count by project" do
        Resource.expects(:dataset).returns(mock {
          expects(:naked).returns(self)
          expects(:group_and_count).returns(self)
          expects(:to_hash).with(:project_id, :count).returns({1 => 123})
        })
        assert_equal({1 => 123}, Resource.count_by_project)
      end
    end
  end
end

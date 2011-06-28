require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestScenario < Coupler::Test::UnitTest
      def setup
        super
        @project = stub('project', :pk => 1, :id => 1, :associations => {})
        @resource_1 = stub('resource 1', :pk => 123, :id => 123, :associations => {}, :status => "ok")
        @resource_2 = stub('resource 2', :pk => 456, :id => 456, :associations => {}, :status => "ok")
        @matcher = stub('matcher', :cross_match? => false, :associations => {})
      end

      def new_scenario(attribs = {})
        values = {
          :name => 'Foo bar',
          :project => @project,
          :resource_1 => @resource_1,
          :matcher => @matcher
        }.update(attribs)
        matcher = values.delete(:matcher)
        s = Scenario.new(values)
        if values[:project]
          s.stubs(:project_dataset).returns(stub({:all => [values[:project]]}))
        end
        if values[:resource_1]
          s.stubs(:resource_1_dataset).returns(stub({:all => [values[:resource_1]]}))
        end
        if values[:resource_2]
          s.stubs(:resource_2_dataset).returns(stub({:all => [values[:resource_2]]}))
        end
        if matcher
          s.stubs(:matcher_dataset).returns(stub({:all => [matcher]}))
        end
        s
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Scenario.superclass
        assert_equal :scenarios, Scenario.table_name
      end

      test "many to one project" do
        assert_respond_to Scenario.new, :project
      end

      test "many to one resource 1" do
        assert_respond_to Scenario.new, :resource_1
      end

      test "many to one resource 2" do
        assert_respond_to Scenario.new, :resource_2
      end

      test "resources" do
        scenario = Scenario.new(:resource_1 => @resource_1)
        assert_equal [@resource_1], scenario.resources
        scenario.resource_2 = @resource_2
        assert_equal [@resource_1, @resource_2], scenario.resources
      end

      test "one to one matcher" do
        assert_respond_to Scenario.new, :matcher
      end

      test "one to many jobs" do
        assert_respond_to Scenario.new, :jobs
      end

      test "one to many results" do
        assert_respond_to Scenario.new, :results
      end

      test "requires name" do
        scenario = new_scenario(:name => nil)
        scenario.expects(:validates_presence).with(:name).returns(false)
        scenario.valid?
      end

      test "requires unique name across projects" do
        scenario = new_scenario
        scenario.expects(:validates_unique).with([:name, :project_id]).returns(false)
        scenario.valid?
      end

      test "requires at least one resource" do
        scenario = new_scenario(:resource_1 => nil)
        assert !scenario.valid?
      end

      test "sets slug from name" do
        scenario = new_scenario.save!
        assert_equal "foo_bar", scenario.slug
      end

      test "setting one resource with resource_ids=" do
        scenario = new_scenario(:resource_1 => nil, :resource_ids => [123])
        resource_1 = @resource_1  # so mocha can resolve it
        @project.expects(:resources_dataset).returns(mock {
          expects(:filter).with(:id => [123]).returns(self)
          expects(:all).returns([resource_1])
        })
        scenario.save!
        assert_equal 123, scenario.resource_1_id
      end

      test "setting two resources with resource ids=" do
        scenario = new_scenario(:resource_1 => nil, :resource_ids => [123, 456])
        resource_1 = @resource_1  # so mocha can resolve it
        resource_2 = @resource_2
        @project.expects(:resources_dataset).returns(mock {
          expects(:filter).with(:id => [123, 456]).returns(self)
          expects(:all).returns([resource_1, resource_2])
        })
        scenario.save!
        assert_equal 123, scenario.resource_1_id
        assert_equal 456, scenario.resource_2_id
      end

      test "doesn't run when there is no matcher" do
        scenario = new_scenario(:matcher => nil).save!
        assert_raises(Scenario::NoMatcherError) { scenario.run! }
      end

      test "doesn't run when resources are out of date" do
        scenario = new_scenario.save!
        @resource_1.expects(:status).returns("out_of_date")
        assert_raises(Scenario::ResourcesOutOfDateError) { scenario.run! }
      end

      test "status with no matcher" do
        scenario = new_scenario(:matcher => nil).save!
        assert_equal "no_matcher", scenario.status
      end

      test "status with matcher" do
        scenario = new_scenario.save!
        assert_equal "ok", scenario.status
      end

      test "status with outdated resources" do
        scenario = new_scenario.save!
        @resource_1.expects(:status).returns("out_of_date")
        assert_equal "resources_out_of_date", scenario.status
      end

      test "linkage type with one resource" do
        scenario = new_scenario.save!
        assert_equal "self-linkage", scenario.linkage_type
      end

      test "linkage type with two resources" do
        scenario = new_scenario(:resource_2 => @resource_2).save!
        assert_equal "dual-linkage", scenario.linkage_type
      end

      test "matcher with cross match makes cross-linkage" do
        scenario = new_scenario.save!
        @matcher.stubs(:cross_match?).returns(true)
        scenario.set_linkage_type
        assert_equal "cross-linkage", scenario.linkage_type
      end

      test "jobified" do
        assert Scenario.ancestors.include?(Jobify)
      end

      #def test_destroying
        #pend
      #end

      test "local database" do
        scenario = new_scenario.save!
        Base.expects(:connection_string).with("scenario_#{scenario.id}").returns("foo")
        db = mock('scenario db')
        Sequel.expects(:connect).with('foo', instance_of(Hash)).returns(db)
        assert_equal db, scenario.local_database
      end

      #def test_deletes_local_database_after_destroy
        #pend
      #end

      #def test_freezes_models_on_run
        #flunk
      #end

      test "count by project" do
        ds = mock('dataset') do
          expects(:naked).returns(self)
          expects(:group_and_count).with(:project_id).returns(self)
          expects(:to_hash).with(:project_id, :count).returns({ 1 => 1 })
        end
        Scenario.expects(:dataset).returns(ds)
        assert_equal({1 => 1}, Scenario.count_by_project)
      end
    end
  end
end

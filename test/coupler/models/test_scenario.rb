require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestScenario < Test::Unit::TestCase
      def db(&block)
        Sequel.connect(Config.connection_string("information_schema"), &block)
      end

      def test_sequel_model
        assert_equal ::Sequel::Model, Scenario.superclass
        assert_equal :scenarios, Scenario.table_name
      end

      def test_many_to_one_project
        assert_respond_to Scenario.new, :project
      end

      def test_many_to_one_resource_1
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        assert_equal resource, scenario.resource_1
      end

      def test_many_to_one_resource_2
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_2 => resource)
        assert_equal resource, scenario.resource_2
      end

      def test_resources
        project = Factory(:project)
        resource_1 = Factory(:resource, :project => project)
        resource_2 = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource_1, :resource_2 => resource_2)
        assert_equal [resource_1, resource_2], scenario.resources
      end

      def test_one_to_one_matcher
        assert_respond_to Scenario.new, :matcher
      end

      def test_one_to_many_jobs
        assert_respond_to Scenario.new, :jobs
      end

      def test_one_to_many_results
        assert_respond_to Scenario.new, :results
      end

      def test_requires_name
        scenario = Factory.build(:scenario, :name => nil)
        assert !scenario.valid?

        scenario.name = ""
        assert !scenario.valid?
      end

      def test_requires_unique_name_across_projects
        project = Factory.create(:project)
        scenario_1 = Factory.create(:scenario, :name => "avast", :project => project)
        scenario_2 = Factory.build(:scenario, :name => "avast", :project => project)
        assert !scenario_2.valid?
      end

      def test_requires_unique_name_on_update
        project = Factory.create(:project)
        scenario_1 = Factory.create(:scenario, :name => "avast", :project => project)
        scenario_2 = Factory.create(:scenario, :name => "ahoy", :project => project)
        scenario_1.name = "ahoy"
        assert !scenario_1.valid?, "Resource wasn't invalid"
      end

      def test_requires_at_least_one_resource
        scenario = Factory.build(:scenario, :resource_ids => [])
        assert !scenario.valid?
      end

      def test_updating
        project = Factory.create(:project)
        scenario = Factory.create(:scenario, :name => "avast", :project => project)
        scenario.save!
      end

      def test_sets_slug_from_name
        scenario = Factory(:scenario, :name => 'Foo bar')
        assert_equal "foo_bar", scenario.slug
      end

      def test_setting_one_resource_with_resource_ids=
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :name => 'Foo bar', :resource_ids => [resource.id.to_s])
        assert_equal resource, scenario.resource_1
      end

      def test_setting_two_resources_with_resource_ids=
        project = Factory(:project)
        resource_1 = Factory(:resource, :project => project)
        resource_2 = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :name => 'Foo bar', :resource_ids => [resource_1.id.to_s, resource_2.id.to_s])
        assert_equal resource_1, scenario.resource_1
        assert_equal resource_2, scenario.resource_2
      end

      def test_doesnt_run_when_there_is_no_matcher
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :name => 'Foo bar', :resource_1 => resource)
        assert_raises(Scenario::NoMatcherError) { scenario.run! }
      end

      def test_doesnt_run_when_resources_are_out_of_date
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :name => 'Foo bar', :resource_1 => resource)
        matcher = Factory(:matcher, :scenario => scenario)

        # make resource out of date
        transformation = Factory(:transformation, :resource => resource)
        assert_raises(Scenario::ResourcesOutOfDateError) { scenario.run! }
      end

      def test_run!
        project = Factory(:project, :name => "Test without transformations")
        resource = Factory(:resource, :name => "Resource 1", :project => project)
        first_name = resource.fields_dataset[:name => 'first_name']
        last_name = resource.fields_dataset[:name => 'last_name']
        scenario = Factory(:scenario, :name => "Scenario 1", :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, {
          :comparisons_attributes => [
            {:lhs_type => 'field', :lhs_value => last_name.id, :rhs_type => 'field', :rhs_value => last_name.id, :operator => 'equals'},
            {:lhs_type => 'field', :lhs_value => first_name.id, :rhs_type => 'field', :rhs_value => first_name.id, :operator => 'equals'},
          ],
          :scenario => scenario
        })

        runner = mock("runner", :run! => nil)
        Scenario::Runner.expects(:new).with(scenario).returns(runner)

        now = Time.now
        Timecop.freeze(now) { scenario.run! }
        assert_equal now, scenario.last_run_at
        assert_equal 1, scenario.run_count
        assert_equal 1, scenario.results_dataset.count

        assert scenario.results_dataset[:run_number => 1]
      end

      def test_status_with_no_matcher
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)

        assert_equal "no_matcher", scenario.status
      end

      def test_status_with_matcher
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, :scenario => scenario)

        assert_equal "ok", scenario.status
      end

      def test_status_with_outdated_resources
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        transformation = Factory(:transformation, :resource => resource)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, :scenario => scenario)

        assert_equal "resources_out_of_date", scenario.status
      end

      def test_linkage_type_with_one_resource
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        assert_equal "self-linkage", scenario.linkage_type
      end

      def test_linkage_type_with_two_resources
        project = Factory(:project)
        resource_1 = Factory(:resource, :project => project)
        resource_2 = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource_1, :resource_2 => resource_2)
        assert_equal "dual-linkage", scenario.linkage_type
      end

      def test_running_jobs
        scenario = Factory(:scenario)
        job = Factory(:scenario_job, :scenario => scenario, :status => 'running')
        assert_equal [job], scenario.running_jobs
      end

      def test_scheduled_jobs
        scenario = Factory(:scenario)
        job = Factory(:scenario_job, :scenario => scenario)
        assert_equal [job], scenario.scheduled_jobs
      end

      def test_destroying
        pend
      end

      def test_local_database
        scenario = Factory(:scenario)
        db do |inf|
          databases = inf["SHOW DATABASES"].collect { |x| x[:Database] }
          inf.run("DROP DATABASE scenario_#{scenario.id}")  if databases.include?("scenario_#{scenario.id}")
        end

        scenario.local_database do |db|
          assert_kind_of Sequel::JDBC::Database, db
          assert_match /scenario_#{scenario.id}/, db.uri
          assert db.test_connection
        end
      end

      def test_deletes_local_database_after_destroy
        pend
      end

      def test_freezes_models_on_run
        flunk
      end

      def test_count_by_project
        project_1 = Factory(:project)
        project_2 = Factory(:project)
        3.times { Factory(:scenario, :project => project_1) }
        2.times { Factory(:scenario, :project => project_2) }
        expected = { project_1.id => 3, project_2.id => 2 }
        assert_equal expected, Scenario.count_by_project
      end
    end
  end
end

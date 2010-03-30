require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestScenario < Test::Unit::TestCase
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

      def test_one_to_many_matchers
        assert_respond_to Scenario.new, :matchers
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

      def test_run_self_join_without_transformations
        database_count = Sequel::DATABASES.length

        Sequel.connect(Config.connection_string("information_schema")) do |inf|
          inf.execute("DROP DATABASE IF EXISTS score_sets")
        end

        project = Factory(:project, :name => "Test without transformations")
        resource = Factory(:resource, :name => "Resource 1", :project => project)
        scenario = Factory(:scenario, {
          :name => "Scenario 1", :project => project,
          :resource_1 => resource
        })
        matcher_1 = Factory(:matcher, {
          :comparator_name => "exact",
          :comparator_options => { resource.id.to_s => {"field_name" => "last_name"} },
          :scenario => scenario
        })
        matcher_2 = Factory(:matcher, {
          :comparator_name => "exact",
          :comparator_options => { resource.id.to_s => {"field_name" => "first_name"} },
          :scenario => scenario
        })

        Timecop.freeze(Time.now) do
          scenario.run!
          assert_equal Time.now, scenario.last_run_at
        end

        result = scenario.results_dataset.first
        assert_not_nil result, "Didn't create result"

        ScoreSet.find(result.score_set_id) do |score_set|
          assert_not_nil score_set, "Didn't create score set"

          resource.source_dataset do |ds|
            ds.order("id").each do |row|
              expected = ds.filter("last_name = ? AND first_name = ? AND id > ?", row[:last_name], row[:first_name], row[:id]).count
              actual = score_set.filter("first_id = ? AND score = 200", row[:id]).count
              assert_equal expected, actual, "Expected #{expected} match for id #{row[:id]}"
            end
          end
        end
      end

      def test_status_with_no_matchers
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)

        assert_equal "no_matchers", scenario.status
      end

      def test_status_with_matchers
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

      def test_run_dual_join_without_transformations
        database_count = Sequel::DATABASES.length

        Sequel.connect(Config.connection_string("information_schema")) do |inf|
          inf.execute("DROP DATABASE IF EXISTS score_sets")
        end

        project = Factory(:project, :name => "Test without transformations")
        resource_1 = Factory(:resource, :name => "People", :project => project)
        resource_2 = Factory(:resource, :name => "Pets", :project => project, :table_name => 'pets')
        scenario = Factory(:scenario, {
          :name => "Scenario 1", :project => project,
          :resource_1 => resource_1, :resource_2 => resource_2
        })

        matcher_1 = Factory(:matcher, {
          :comparator_name => "exact",
          :comparator_options => {
            resource_1.id.to_s => { "field_name" => "last_name" },
            resource_2.id.to_s => { "field_name" => "owner_last_name" }
          },
          :scenario => scenario
        })
        matcher_2 = Factory(:matcher, {
          :comparator_name => "exact",
          :comparator_options => {
            resource_1.id.to_s => { "field_name" => "first_name" },
            resource_2.id.to_s => { "field_name" => "owner_first_name" }
          },
          :scenario => scenario
        })

        Timecop.freeze(Time.now) do
          scenario.run!
          assert_equal Time.now, scenario.last_run_at
        end

        result = scenario.results_dataset.first
        assert_not_nil result, "Didn't create result"

        ScoreSet.find(result.score_set_id) do |score_set|
          assert_not_nil score_set, "Didn't create score set"

          resource_1.source_dataset do |ds_1|
            resource_2.source_dataset do |ds_2|
              ds_1.order("id").each do |row_1|
                expected = ds_2.filter("owner_last_name = ? AND owner_first_name = ?", row_1[:last_name], row_1[:first_name]).count
                actual = score_set.filter("first_id = ? AND score = 200", row_1[:id]).count
                assert_equal expected, actual, "Expected #{expected} for id #{row_1[:id]}"
              end
            end
          end
        end
      end

      def test_run_uses_correct_key
        Sequel.connect(Config.connection_string("information_schema")) do |inf|
          inf.execute("DROP DATABASE IF EXISTS score_sets")
        end

        project = Factory(:project, :name => "Test")
        resource = Factory(:resource, :name => "Resource 1", :project => project, :table_name => "avast_ye")
        scenario = Factory(:scenario, {
          :name => "Scenario 1", :project => project,
          :resource_1 => resource
        })
        matcher = Factory(:matcher, {
          :comparator_name => "exact",
          :comparator_options => { resource.id.to_s => {"field_name" => "scurvy_dog"} },
          :scenario => scenario
        })

        Timecop.freeze(Time.now) do
          scenario.run!
          assert_equal Time.now, scenario.last_run_at
        end

        result = scenario.results_dataset.first
        assert_not_nil result, "Didn't create result"

        ScoreSet.find(result.score_set_id) do |score_set|
          assert_not_nil score_set, "Didn't create score set"

          resource.source_dataset do |ds|
            ds.order("arrr").each do |row|
              expected = ds.filter("scurvy_dog = ? AND arrr > ?", row[:scurvy_dog], row[:arrr]).count
              actual = score_set.filter("first_id = ? AND score = 100", row[:id]).count
              assert_equal expected, actual, "Expected #{expected} for id #{row[:id]}"
            end
          end
        end
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
    end
  end
end

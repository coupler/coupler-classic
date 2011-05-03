require 'helper'

class TestField < Coupler::Test::IntegrationTest
  def self.startup
    super
    Connection.delete
    each_adapter do |adapter, config|
      data = Array.new(50) { [Forgery(:name).first_name, Forgery(:name).last_name] }
      conn = new_connection(adapter, :name => "#{adapter} connection").save!
      conn.database do |db|
        db.create_table!(:test_data) do
          primary_key :id
          String :first_name
          String :last_name
        end
        db[:test_data].import([:first_name, :last_name], data)
      end
    end
  end

  each_adapter do |adapter, _|
    adapter_test(adapter, "scenarios_dataset") do
      connection = new_connection(adapter, :name => "#{adapter} connection").save!
      project = Project.create(:name => "foo")
      resource = Resource.create({
        :name => "Test resource", :table_name => 'test_data',
        :project => project, :connection => connection
      })
      scenario = Scenario.create({
        :name => "Test scenario",
        :resource_1 => resource, :project => project
      })
      first_name = resource.fields_dataset[:name => 'first_name']
      matcher = Matcher.create({
        :scenario => scenario,
        :comparisons_attributes => [
          {:lhs_type => 'field', :raw_lhs_value => first_name.id, :lhs_which => 1, :rhs_type => 'field', :raw_rhs_value => first_name.id, :rhs_which => 2, :operator => 'equals'},
        ],
      })

      ds = first_name.scenarios_dataset
      assert_equal scenario.id, ds.get(:scenarios__id)
    end
  end
end

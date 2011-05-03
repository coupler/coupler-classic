require 'helper'

class TestRunningScenarios < Coupler::Test::IntegrationTest

  def self.startup
    super
    Connection.delete
    each_adapter do |adapter, config|
      conn = new_connection(adapter, :name => "#{adapter} connection").save!
      conn.database do |db|
        tables = db.tables
        db.drop_table(:basic_self_linkage)  if tables.include?(:basic_self_linkage)
        db.drop_table(:basic_cross_linkage) if tables.include?(:basic_cross_linkage)
        TableMaker.new(db, :basic_self_linkage, <<-EOF)
          +-------------+-------------+
          | id(Integer) | foo(String) |
          +=============+=============+
          | 1           | foo         |
          | 2           | foo         |
          | 3           | foo         |
          | 4           | foo         |
          | 5           | foo         |
          | 6           | bar         |
          | 7           | bar         |
          | 8           | bar         |
          | 9           | bar         |
          | 10          | bar         |
          | 11          | baz         |
          | 12          | baz         |
          | 13          | baz         |
          | 14          | baz         |
          | 15          | baz         |
          | 16          | abc         |
          | 17          | def         |
          | 18          | ghi         |
          | 19          | jkl         |
          | 20          | mno         |
          +-------------+-------------+
        EOF

        TableMaker.new(db, :basic_cross_linkage, <<-EOF)
          +-------------+-------------+-------------+
          | id(Integer) | foo(String) | bar(String) |
          +=============+=============+=============+
          | 18          | foo         |             |
          | 16          | foo         |             |
          | 17          | foo         |             |
          | 15          |             | foo         |
          | 13          |             | foo         |
          | 10          |             | foo         |
          | 19          |             | foo         |
          | 25          | bar         |             |
          | 23          | bar         |             |
          | 20          | bar         |             |
          | 29          | bar         |             |
          | 28          |             | bar         |
          | 26          |             | bar         |
          | 27          |             | bar         |
          | 38          | baz         |             |
          | 35          |             | baz         |
          | 33          |             | baz         |
          | 30          |             | baz         |
          | 39          |             | baz         |
          | 45          | quux        |             |
          | 43          | quux        |             |
          | 40          | quux        |             |
          | 49          | quux        |             |
          | 48          |             | quux        |
          | 55          | ditto       | ditto       |
          | 53          | ditto       | ditto       |
          +-------------+-------------+-------------+
        EOF
      end
    end
  end

  #def self.shutdown
    #each_adapter do |adapter, config|
      #conn = Connection[:name => "#{adapter} connection"]
      #conn.database do |db|
        #db.drop_table(:basic_cross_linkage)
        #db.drop_table(:basic_self_linkage)
      #end
    #end
    #super
  #end

  def setup
    super
    @project = Project.create(:name => "foo")
  end

  each_adapter do |adapter, _|
    adapter_test(adapter, "default csv export self linkage") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'foo', :table_name => 'basic_self_linkage', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      foo_field = resource.fields_dataset[:name => 'foo']
      matcher = Matcher.create({
        :scenario => scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo_field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => foo_field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      count = 0
      scenario.run! { |n| count += n }
      assert_not_nil scenario.last_run_at
      assert_equal 1, scenario.run_count
      assert_equal 1, scenario.results_dataset.count

      result = scenario.results_dataset.first
      csv = result.to_csv

      # FIXME: add some actual csv tests you lazy bastard
    end

    adapter_test(adapter, "default csv export cross linkage") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'foo', :table_name => 'basic_cross_linkage', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      foo_field = resource.fields_dataset[:name => 'foo']
      bar_field = resource.fields_dataset[:name => 'bar']
      matcher = Matcher.create({
        :scenario => scenario,
        :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => foo_field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => bar_field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      scenario.run!
      result = scenario.results_dataset.first
      csv = result.to_csv

      # FIXME: add some actual csv tests you lazy bastard
    end
  end
end

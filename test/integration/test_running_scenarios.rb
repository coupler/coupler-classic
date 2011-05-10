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

        db.create_table!(:resource_1) do
          primary_key :id
          String :ssn, :index => true
          String :dob, :index => true
          Integer :foo, :index => true
          Integer :bar, :index => true
          Integer :age, :index => true
          Integer :height, :index => true
          index [:id, :ssn]
          index [:id, :ssn, :dob]
          index [:id, :foo, :bar]
          index [:id, :age]
        end
        rows = Array.new(11000) do |i|
          [
            i < 10500 ? "1234567%02d"  % (i / 350) : "9876%05d" % i,
            i < 10500 ? "2000-01-%02d" % (i / 525) : nil,
            i < 1000 ? ((x = i / 125) == 2 ? 123 : x) : nil,
            i < 1000 ? i % 10 : nil,
            i % 20 + 25,
            i % 50 + 125,
          ]
        end
        db[:resource_1].import([:ssn, :dob, :foo, :bar, :age, :height], rows)

        db.create_table!(:resource_2) do
          primary_key :id
          String :SocialSecurityNumber
          index [:id, :SocialSecurityNumber]
        end
        rows = Array.new(21000) do |i|
          [
            i < 10500 ? "1234567%02d" % (i % 30) : "9876%05d" % i,
          ]
        end
        db[:resource_2].import([:SocialSecurityNumber], rows)
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
      scenario.run!
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

    adapter_test(adapter, "self linkage with one comparison") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'resource_1', :table_name => 'resource_1', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      field = resource.fields_dataset[:name => 'ssn']
      matcher = Matcher.create({
        :scenario => scenario, :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => field.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => field.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      scenario.run!

      groups = {}
      scenario.local_database do |db|
        assert db.tables.include?(:groups_records_1)
        ds = db[:groups_records_1]
        assert_equal 10500, ds.count
        counts = ds.group_and_count(:group_id).all
        assert_equal 30, counts.length
        assert counts.all? { |g| g[:count] == 350 }
        assert ds.group_and_count(:record_id).all? { |r| r[:count] == 1 }
        ds.each do |row|
          record_id = groups[row[:group_id]]
          if record_id
            assert_equal (record_id - 1) / 350, (row[:record_id].to_i - 1) / 350, "Record #{row[:record_id]} should not have been in the same group as Record #{record_id}."
          else
            groups[row[:group_id]] = row[:record_id].to_i
          end
        end
      end
    end

    adapter_test(adapter, "self linkage with two comparisons") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'resource_1', :table_name => 'resource_1', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      field_1 = resource.fields_dataset[:name => 'ssn']
      field_2 = resource.fields_dataset[:name => 'dob']
      matcher = Matcher.create({
        :scenario => scenario, :comparisons_attributes => [
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_1.id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => field_1.id, 'rhs_which' => 2,
            'operator' => 'equals'
          },
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_2.id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => field_2.id, 'rhs_which' => 2,
            'operator' => 'equals'
          },
        ]
      })
      scenario.run!

      groups = {}
      scenario.local_database do |db|
        assert db.tables.include?(:groups_records_1)
        ds = db[:groups_records_1]
        assert_equal 10500, ds.count

        counts = ds.group_and_count(:group_id)
        assert_equal 20, counts.having(:count => 175).count
        assert_equal 20, counts.having(:count => 350).count
        assert ds.group_and_count(:record_id).all? { |r| r[:count] == 1 }
        ds.each do |row|
          record_id = groups[row[:group_id]]
          if record_id
            assert_equal (record_id - 1) / 350, (row[:record_id].to_i - 1) / 350, "Record #{row[:record_id]} should not have been in the same group as Record #{record_id}."
            assert_equal (record_id - 1) / 525, (row[:record_id].to_i - 1) / 525, "Record #{row[:record_id]} should not have been in the same group as Record #{record_id}."
          else
            groups[row[:group_id]] = row[:record_id].to_i
          end
        end
      end
    end

    adapter_test(adapter, "self linkage with cross match") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'resource_1', :table_name => 'resource_1', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      field_1 = resource.fields_dataset[:name => 'foo']
      field_2 = resource.fields_dataset[:name => 'bar']
      matcher = Matcher.create({
        :scenario => scenario, :comparisons_attributes => [
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_1.id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => field_2.id, 'rhs_which' => 2,
            'operator' => 'equals'
          },
        ]
      })
      scenario.run!

      groups = {}
      scenario.local_database do |db|
        assert db.tables.include?(:groups_records_1)
        join_ds = db[:groups_records_1]
        # Breakdown of groups_records_1
        # - Values that should match each other: 0, 1, 3, 4, 5, 6, 7
        # - For each value, there are 125 records that should match in foo
        #   Subtotal: 875
        # - For each value, there are 100 records that should match in bar
        #   Subtotal: 700
        # * Expected Total: 1575
        assert_equal 1575, join_ds.count

        assert db.tables.include?(:groups_1)
        group_ds = db[:groups_1]
        assert_equal 7, group_ds.count
        group_ds.each do |group_row|
          assert_equal 125, group_row[:"resource_1_count"], "Row counts didn't match"
          assert_equal 100, group_row[:"resource_2_count"], "Row counts didn't match"
        end

        assert_equal 0, join_ds.group_and_count(:group_id).having(:count => 1).count
      end
    end

    adapter_test(adapter, "self linkage with blocking") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource = Resource.create(:name => 'resource_1', :table_name => 'resource_1', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource, :project => @project)
      field_1 = resource.fields_dataset[:name => 'age']
      field_2 = resource.fields_dataset[:name => 'height']
      matcher = Matcher.create({
        :scenario => scenario, :comparisons_attributes => [
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_1.id, 'lhs_which' => 1,
            'rhs_type' => 'field', 'raw_rhs_value' => field_1.id, 'rhs_which' => 2,
            'operator' => 'equals'
          },
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_1.id, 'lhs_which' => 1,
            'rhs_type' => 'integer', 'raw_rhs_value' => 30,
            'operator' => 'greater_than'
          },
          {
            'lhs_type' => 'field', 'raw_lhs_value' => field_2.id, 'lhs_which' => 1,
            'rhs_type' => 'integer', 'raw_rhs_value' => 150,
            'operator' => 'greater_than'
          },
        ]
      })
      scenario.run!

      groups = {}
      scenario.local_database do |db|
        assert db.tables.include?(:groups_records_1)
        ds = db[:groups_records_1]
        assert ds.group_and_count(:record_id).all? { |r| r[:count] == 1 }
        ds.each do |row|
          index = row[:record_id].to_i - 1
          assert index % 20 > 5,  "#{row[:record_id]}'s age is too small"
          assert index % 50 > 25, "#{row[:record_id]}'s height is too small"

          record_id = groups[row[:group_id]]
          if record_id
            assert_equal (record_id - 1) % 20 + 25, (row[:record_id].to_i - 1) % 20 + 25, "Record #{row[:record_id]} should not have been in the same group as Record #{record_id}."
          else
            groups[row[:group_id]] = row[:record_id].to_i
          end
        end
      end
    end

    adapter_test(adapter, "dual linkage with one comparison") do
      conn = new_connection(adapter, :name => :"#{adapter} connection").save!
      resource_1 = Resource.create(:name => 'resource_1', :table_name => 'resource_1', :project => @project, :connection => conn)
      resource_2 = Resource.create(:name => 'resource_2', :table_name => 'resource_2', :project => @project, :connection => conn)
      scenario = Scenario.create(:name => 'foo', :resource_1 => resource_1, :resource_2 => resource_2, :project => @project)
      field_1 = resource_1.fields_dataset[:name => 'ssn']
      field_2 = resource_2.fields_dataset[:name => 'SocialSecurityNumber']
      assert field_1, "ssn field couldn't be found: #{resource_1.fields_dataset.collect(&:name).inspect}"
      assert field_2, "socialsecuritynumber field couldn't be found: #{resource_2.fields_dataset.collect(&:name).inspect}"
      matcher = Matcher.create({
        :scenario => scenario, :comparisons_attributes => [{
          'lhs_type' => 'field', 'raw_lhs_value' => field_1.id, 'lhs_which' => 1,
          'rhs_type' => 'field', 'raw_rhs_value' => field_2.id, 'rhs_which' => 2,
          'operator' => 'equals'
        }]
      })
      scenario.run!

      groups = {}
      scenario.local_database do |db|
        assert db.tables.include?(:groups_records_1)
        ds = db[:groups_records_1]
        assert_equal 22000, ds.count

        counts = ds.group_and_count(:group_id).all
        assert_equal 530, counts.length
        counts = counts.inject({}) { |h, r| h[r[:count]] ||= 0; h[r[:count]] += 1; h }
        assert_equal 30, counts[700]
        assert_equal 500, counts[2]
        assert ds.group_and_count(:record_id, :which).all? { |r| r[:count] == 1 }

        ds = db[:groups_1]
        assert_equal 530, ds.count
      end
    end
  end
end

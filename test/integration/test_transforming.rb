require 'helper'

class TestTransforming < Coupler::Test::IntegrationTest

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

  def setup
    super
    @project = Project.create(:name => "Test project")
  end

  def adapter_setup(adapter)
    @connection = new_connection(adapter, :name => "#{adapter} connection").save!
    @resource = Resource.create(:name => "Test resource", :table_name => 'test_data', :project => @project, :connection => @connection)
    @transformer = Transformer.create(:name => "downcaser", :allowed_types => %w{string}, :code => 'value.downcase', :result_type => 'same')
  end

  each_adapter do |adapter, _|
    adapter_test(adapter, "single transformation") do
      adapter_setup(adapter)
      transformation = Transformation.create({
        :resource => @resource, :transformer => @transformer,
        :source_field => @resource.fields_dataset[:name => 'first_name']
      })

      @resource.transform!
      assert @resource.transformed_at
      assert_equal "#{transformation.id}", @resource.transformed_with
      assert_equal "ok", @resource.status

      @connection.database do |source_db|
        @project.local_database do |local_db|
          table_name = :"resource_#{@resource.id}"
          assert_equal :string, local_db.schema(table_name).assoc(:first_name)[1][:type]
          local_ds = local_db[table_name]
          source_db[:test_data].each do |source_row|
            local_row = local_ds[:id => source_row[:id]]
            assert_equal source_row[:first_name].downcase, local_row[:first_name]
          end
        end
      end
    end

    adapter_test(adapter, "transform goes in order of position") do
      adapter_setup(adapter)
      first_name = @resource.fields_dataset[:name => 'first_name']
      foo_transformer = Transformer.create(:name => "foo", :allowed_types => %w{string}, :code => '"FOO"', :result_type => 'same')
      xformation_1 = Transformation.create(:resource => @resource, :transformer => @transformer, :source_field => first_name)
      xformation_2 = Transformation.create(:resource => @resource, :transformer => foo_transformer, :source_field => first_name)
      xformation_1.update(:position => 2)
      xformation_2.update(:position => 1)

      @resource.transform!
      @resource.local_dataset do |ds|
        ds.each { |r| assert_equal "foo", r[:first_name] }
      end
    end

    adapter_test(adapter, "transform into new result field") do
      adapter_setup(adapter)
      transformation = Transformation.create({
        :resource => @resource, :transformer => @transformer,
        :source_field => @resource.fields_dataset[:name => 'first_name'],
        :result_field_attributes => { :name => 'downcased_first_name' }
      })
      @resource.transform!
      @resource.local_dataset do |ds|
        ds.each { |r| assert_equal r[:first_name].downcase, r[:downcased_first_name] }
      end
    end

    adapter_test(adapter, "transforming only gets specified columns") do
      adapter_setup(adapter)
      @resource.fields_dataset.filter(["name IN ?", %w{last_name}]).update(:is_selected => false)
      transformation = Transformation.create({
        :resource => @resource, :transformer => @transformer,
        :source_field => @resource.fields_dataset[:name => 'first_name']
      })
      @resource.transform!
      @project.local_database do |db|
        schema = db.schema(:"resource_#{@resource.id}")
        assert_equal [:id, :first_name], schema.collect(&:first)
      end
    end

    adapter_test(adapter, "preview inplace transformation") do
      adapter_setup(adapter)
      strlen = Transformer.create(:name => "strlen", :code => 'value.length', :allowed_types => %w{string}, :result_type => 'integer')
      square = Transformer.create(:name => 'square', :code => "value ** 2", :allowed_types => %w{integer}, :result_type => 'integer')
      first_name = @resource.fields_dataset[:name => 'first_name']
      transformation_1 = Transformation.create({
        :resource => @resource, :transformer => strlen,
        :source_field => first_name
      })
      transformation_2 = Transformation.new({
        :resource => @resource, :transformer => square,
        :source_field => first_name, :result_field => first_name
      })
      arr = @resource.preview_transformation(transformation_2)
      assert_equal [:id, :first_name, :last_name], arr[:fields]
      assert_equal 50, arr[:data].length
      @resource.source_dataset do |ds|
        ds.limit(50).each_with_index do |row, i|
          before = row.merge(:first_name => row[:first_name].length)
          after  = before.merge(:first_name => before[:first_name] ** 2)
          result = arr[:data].find { |r| r[:before][:id] == row[:id] }
          assert_equal before, result[:before], "Before didn't match"
          assert_equal after, result[:after], "After didn't match"
        end
      end
    end

    adapter_test(adapter, "preview transformation with invalid transformer") do
      adapter_setup(adapter)
      first_name = @resource.fields_dataset[:name => 'first_name']
      transformation = Transformation.new({
        :resource => @resource, :source_field => first_name,
        :result_field => first_name, :transformer => nil,
        :transformer_attributes => { :name => "foo", :code => "HAY", :allowed_types => %w{string}, :result_type => "string" }
      })
      result = @resource.preview_transformation(transformation)
      assert_kind_of Exception, result
    end

    adapter_test(adapter, "transform with progress callback") do
      adapter_setup(adapter)
      first_name = @resource.fields_dataset[:name => 'first_name']
      transformation = Transformation.create({
        :resource => @resource, :source_field => first_name,
        :result_field => first_name, :transformer => @transformer
      })
      count = 0
      @resource.transform! do |n|
        count += 1
      end
      assert count > 0
    end
  end
end

require 'helper'

class TestTransformation < Coupler::Test::IntegrationTest
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

  def adapter_setup(adapter)
    @connection = new_connection(adapter, :name => "#{adapter} connection").save!
    @project = Project.create(:name => 'foo')
    @resource = Resource.create(:name => 'test', :connection => @connection, :table_name => 'test_data', :project => @project)
  end

  each_adapter do |adapter, _|
    adapter_test(adapter, "uses local db type to determine field type") do
      adapter_setup(adapter)
      string_to_int = Transformer.create(:name => 'string_to_int', :allowed_types => %w{string}, :code => "value.length", :result_type => "integer")
      int_to_string = Transformer.create(:name => 'int_to_string', :allowed_types => %w{integer}, :code => "value.to_s", :result_type => "string")
      field = @resource.fields_dataset[:name => 'first_name']
      xformation_1 = Transformation.create(:transformer => string_to_int, :source_field => field, :resource => @resource)
      xformation_2 = Transformation.new(:transformer => int_to_string, :source_field => field, :resource => @resource)
      assert xformation_2.valid?, xformation_2.errors.full_messages.join("; ")
    end

    adapter_test(adapter, "accepts nested attributes for result field") do
      adapter_setup(adapter)
      transformer = Transformer.create({
        :name => "noop",
        :code => %{value},
        :allowed_types => %w{string integer datetime},
        :result_type => 'same'
      })
      field = @resource.fields_dataset[:name => 'first_name']
      transformation = Transformation.create({
        :transformer => transformer,
        :resource => @resource,
        :source_field => field,
        :result_field_attributes => { :name => 'new_first_name' }
      })

      result_field = transformation.result_field.refresh
      assert_equal field[:type], result_field[:type]
      assert_equal field[:db_type], result_field[:db_type]
      assert result_field[:is_generated]
    end

  end
end

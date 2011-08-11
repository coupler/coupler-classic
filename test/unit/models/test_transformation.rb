require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestTransformation < Coupler::Test::UnitTest
      def new_transformation(attribs = {})
        values = {
          :transformer => @transformer,
          :resource => @resource,
          :source_field => @source_field
        }.update(attribs)
        t = Transformation.new(values)
        if values[:transformer]
          t.stubs(:transformer_dataset).returns(stub({:all => [values[:transformer]]}))
        end
        if values[:source_field]
          t.stubs(:source_field_dataset).returns(stub({:all => [values[:source_field]]}))
          if values[:resource]
            values[:resource].stubs(:fields_dataset).returns(stub('fields dataset') {
              stubs(:[]).with(:id => values[:source_field].id).returns(values[:source_field])
            })
          end
        end
        if values[:result_field]
          t.stubs(:result_field_dataset).returns(stub({:all => [values[:result_field]]}))
        end
        if values[:resource]
          t.stubs(:resource_dataset).returns(stub({:all => [values[:resource]]}))
          values[:resource].stubs(:fields_dataset).returns(stub('fields dataset') {
            stubs(:[]).returns(nil)
            if values[:source_field]
              stubs(:[]).with(:id => values[:source_field].id).returns(values[:source_field])
            end
            if values[:result_field]
              stubs(:[]).with(:id => values[:result_field].id).returns(values[:result_field])
            end
          })
        end
        t
      end

      def setup
        super
        @resource = stub('resource', :pk => 3, :id => 3, :associations => {}, :transformations_updated! => nil)
        @transformer = stub('transformer', {
          :pk => 1, :id => 1, :associations => {},
          :allowed_types => %w{string}, :name => "foobar"
        })
        @source_field = stub('source_field', {
          :pk => 7, :id => 7, :associations => {},
          :final_type => 'string', :name => 'first_name'
        })
        @result_field = stub('result_field', {
          :pk => 8, :id => 8, :associations => {},
          :final_type => 'string', :name => 'new_first_name'
        })
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Transformation.superclass
        assert_equal :transformations, Transformation.table_name
      end

      test "many to one resource" do
        assert_respond_to Transformation.new, :resource
      end

      test "many to one source field" do
        assert_respond_to Transformation.new, :source_field
      end

      test "many to one result field" do
        assert_respond_to Transformation.new, :result_field
      end

      test "requires resource id" do
        transformation = new_transformation(:resource => nil)
        assert !transformation.valid?
      end

      test "requires existing transformer or nested attributes" do
        transformation = new_transformation(:transformer => nil)
        assert !transformation.valid?
      end

      test "requires correct field type" do
        @source_field.stubs(:final_type).returns('integer')
        transformation = new_transformation
        assert !transformation.valid?
      end

      test "requires existing source field" do
        transformation = new_transformation(:source_field => nil, :source_field_id => 1337)
        assert !transformation.valid?
      end

      test "result field same as source field by default" do
        transformation = new_transformation.save!
        assert_equal transformation.result_field_id, @source_field.id
      end

      test "requires existing result field or nested attributes" do
        transformation = new_transformation(:result_field_id => 1337)
        assert !transformation.valid?
      end

      test "accepts nested attributes for transformer" do
        assert_respond_to Transformation.new, :transformer_attributes=
      end

      test "transform with same source and result field" do
        transformation = new_transformation(:result_field => @source_field).save!

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        @transformer.expects(:transform).with(data, { :in => :first_name, :out => :first_name }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      test "transform with differing source and result field" do
        transformation = new_transformation(:result_field => @result_field)

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        transformation.transformer.expects(:transform).with(data, { :in => :first_name, :out => :new_first_name }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      test "field changes" do
        transformation = new_transformation.save!
        result = stub('result')
        @transformer.expects(:field_changes).with(@source_field).returns(result)
        assert_equal result, transformation.field_changes
      end

      test "updates resource fields on save" do
        transformation = new_transformation
        @resource.expects(:transformations_updated!)
        transformation.save!
      end

      #def test_updates_resource_fields_on_destroy
        #pend
      #end

      test "deletes orphaned result field on destroy" do
        @result_field.stubs(:is_generated).returns(true)
        @result_field.stubs(:scenarios_dataset).returns(stub(:count => 0))
        transformation = new_transformation(:result_field => @result_field).save!
        Transformation.expects(:filter).with(:result_field_id => 8).returns(mock(:count => 0))
        @result_field.expects(:destroy)
        transformation.destroy
      end

      test "does not delete result field in use by other transformation" do
        @result_field.stubs(:is_generated).returns(true)
        @result_field.stubs(:scenarios_dataset).returns(stub(:count => 0))
        transformation = new_transformation(:result_field => @result_field).save!
        Transformation.expects(:filter).with(:result_field_id => 8).returns(mock(:count => 1))
        @result_field.expects(:destroy).never
        transformation.destroy
      end

      test "prevents deletion if result field is in use by scenario" do
        @result_field.stubs(:is_generated).returns(true)
        @result_field.stubs(:scenarios_dataset).returns(stub(:count => 1))
        transformation = new_transformation(:result_field => @result_field).save!
        assert !transformation.destroy
      end

      test "prevents deletion unless in last position" do
        transformation_1 = new_transformation(:position => 1).save!
        transformation_2 = new_transformation(:position => 2).save!
        assert !transformation_1.destroy
        assert_not_nil Transformation[:id => transformation_1.id]
      end

      test "sets position by resource" do
        resource_1 = stub('resource', :pk => 1, :id => 1, :associations => {}, :transformations_updated! => nil)
        resource_2 = stub('resource', :pk => 2, :id => 2, :associations => {}, :transformations_updated! => nil)

        xformation_1 = new_transformation(:resource => resource_1).save!
        xformation_2 = new_transformation(:resource => resource_1).save!
        xformation_3 = new_transformation(:resource => resource_2).save!
        assert_equal 1, xformation_1.position
        assert_equal 2, xformation_2.position
        assert_equal 1, xformation_3.position
      end
    end
  end
end

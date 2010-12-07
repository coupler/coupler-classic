require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestTransformation < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Transformation.superclass
        assert_equal :transformations, Transformation.table_name
      end

      def test_many_to_one_resource
        assert_respond_to Transformation.new, :resource
      end

      def test_many_to_one_source_field
        assert_respond_to Transformation.new, :source_field
      end

      def test_many_to_one_result_field
        assert_respond_to Transformation.new, :result_field
      end

      def test_requires_resource_id
        transformation = Factory.build(:transformation, :resource => nil)
        assert !transformation.valid?
      end

      def test_requires_existing_transformer_or_nested_attributes
        transformation = Factory.build(:transformation, :transformer => nil)
        assert !transformation.valid?
      end

      def test_requires_correct_field_type
        transformer = Factory(:transformer, :allowed_types => %w{integer})
        resource = Factory(:resource)
        field = resource.fields_dataset.first
        transformation = Factory.build(:transformation, :transformer => transformer, :source_field => field)
        assert !transformation.valid?
      end

      def test_uses_local_db_type_to_determine_field_type
        string_to_int = Factory(:transformer, :allowed_types => %w{string}, :code => "value.length", :result_type => "integer")
        int_to_string = Factory(:transformer, :allowed_types => %w{integer}, :code => "value.to_s", :result_type => "string")
        resource = Factory(:resource)
        field = resource.fields_dataset[:name => 'first_name']
        xformation_1 = Factory(:transformation, :transformer => string_to_int, :source_field => field, :resource => resource)
        xformation_2 = Factory.build(:transformation, :transformer => int_to_string, :source_field => field, :resource => resource)
        assert xformation_2.valid?, xformation_2.errors.full_messages.join("; ")
      end

      def test_requires_existing_source_field
        transformation = Factory.build(:transformation, :source_field => nil, :source_field_id => 1337)
        assert !transformation.valid?
      end

      def test_result_field_same_as_source_field_by_default
        resource = Factory(:resource)
        field = resource.fields_dataset.first
        transformation = Factory(:transformation, :source_field => field, :resource => resource)
        assert_equal field.id, transformation.result_field_id
      end

      def test_accepts_nested_attributes_for_result_field
        resource = Factory(:resource)
        field = resource.fields_dataset[:name => "first_name"]
        transformer = Factory(:transformer, :code => %w{value}, :result_type => 'same')

        count = resource.fields_dataset.count
        transformation = Factory(:transformation, {
          :resource => resource,
          :source_field => field,
          :result_field_attributes => { :name => 'new_first_name' }
        })
        assert_equal count + 1, resource.fields_dataset.count

        result_field = transformation.result_field.refresh
        assert_equal field[:type], result_field[:type]
        assert_equal field[:db_type], result_field[:db_type]
        assert result_field[:is_generated]
      end

      def test_requires_existing_result_field_or_nested_attributes
        transformation = Factory.build(:transformation, :result_field_id => 1337)
        assert !transformation.valid?
      end

      def test_accepts_nested_attributes_for_transformer
        count = Transformer.count
        transformation = Factory(:transformation, {
          :transformer => nil,
          :transformer_attributes => Factory.attributes_for(:transformer)
        })
        assert_equal count + 1, Transformer.count
      end

      def test_handles_bad_transformer_attributes_on_save
        transformation = Factory.build(:transformation, {
          :transformer => nil,
          :transformer_attributes => Factory.attributes_for(:transformer, :allowed_types => nil)
        })
        assert !transformation.valid?
      end

      def test_transform_with_same_source_and_result_field
        transformer = Factory(:transformer)
        resource = Factory(:resource)
        transformation = Factory(:transformation, {
          :transformer => transformer,
          :resource => resource,
          :source_field => resource.fields_dataset[:name => 'first_name']
        })

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        transformation.transformer.expects(:transform).with(data, { :in => :first_name, :out => :first_name }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      def test_transform_with_differing_source_and_result_field
        transformer = Factory(:transformer)
        resource = Factory(:resource)
        transformation = Factory(:transformation, {
          :transformer => transformer,
          :resource => resource,
          :source_field => resource.fields_dataset[:name => 'first_name'],
          :result_field_attributes => { :name => 'first_name_2' }
        })

        data = {:id => 1, :first_name => "Peter"}
        expected = stub("result")
        transformation.transformer.expects(:transform).with(data, { :in => :first_name, :out => :first_name_2 }).returns(expected)

        assert_equal expected, transformation.transform(data)
      end

      def test_field_changes
        transformer = Factory(:transformer)
        resource = Factory(:resource)
        field = resource.fields_dataset.first
        transformation = Factory(:transformation, {
          :transformer => transformer, :resource => resource,
          :source_field => field
        })

        result = stub('result')
        transformation.transformer.expects(:field_changes).with(transformation.source_field).returns(result)
        assert_equal result, transformation.field_changes
      end

      def test_updates_resource_fields_on_save
        transformer = Factory.build(:transformer)
        resource = Factory.build(:resource)
        Timecop.freeze(Time.now - 1000) do
          transformer.save
          resource.save
        end
        field = resource.fields_dataset.first
        time = field.updated_at
        transformation = Factory(:transformation, :resource => resource, :transformer => transformer, :source_field => field)
        field.refresh
        assert field.updated_at > time, "#{field.updated_at} isn't more recent than #{time}"
      end

      def test_updates_resource_fields_on_destroy
        pend
      end

      def test_deletes_orphaned_result_field_on_destroy
        resource = Factory(:resource)
        source_field = resource.fields_dataset[:name => "first_name"]
        transformation = Factory(:transformation, {
          :resource => resource,
          :source_field => source_field,
          :result_field_attributes => { :name => 'new_first_name' }
        })
        result_field = transformation.result_field
        transformation.destroy
        assert_nil Field[:id => result_field.id]
      end

      def test_does_not_delete_result_field_in_use_by_other_transformation
        resource = Factory(:resource)
        source_field = resource.fields_dataset[:name => "first_name"]
        transformation_1 = Factory(:transformation, {
          :resource => resource,
          :source_field => source_field,
          :result_field_attributes => { :name => 'new_first_name' }
        })
        transformation_2 = Factory(:transformation, {
          :resource => resource,
          :source_field => transformation_1.result_field
        })
        result_field = transformation_1.result_field
        transformation_2.destroy
        assert Field[:id => result_field.id]
      end

      def test_prevents_deletion_if_result_field_is_in_use_by_scenario
        project = Factory(:project)
        resource = Factory(:resource, :project => project)
        source_field = resource.fields_dataset[:name => "first_name"]
        transformation = Factory(:transformation, {
          :resource => resource,
          :source_field => source_field,
          :result_field_attributes => { :name => 'new_first_name' }
        })
        result_field = transformation.result_field
        scenario = Factory(:scenario, :project => project, :resource_1 => resource)
        matcher = Factory(:matcher, {
          :comparisons_attributes => [
            {:lhs_type => 'field', :raw_lhs_value => source_field.id, :rhs_type => 'field', :raw_rhs_value => result_field.id, :operator => 'equals'},
          ],
          :scenario => scenario
        })
        assert !transformation.destroy
      end

      def test_prevents_deletion_unless_in_last_position
        # FIXME: this is temporary, but I don't want to program the
        # complex logic to enable deletion from the middle of a
        # transformation stack
        resource = Factory(:resource)
        transformation_1 = Factory(:transformation, :resource => resource)
        transformation_2 = Factory(:transformation, :resource => resource)
        transformation_1.destroy
        assert_not_nil Transformation[:id => transformation_1.id]
      end

      def test_sets_position_by_resource
        transformer = Factory(:transformer)
        resource_1 = Factory(:resource)
        resource_2 = Factory(:resource)
        opts = { :transformer => transformer, :resource => resource_1 }
        xformation_1 = Factory(:transformation, opts)
        xformation_2 = Factory(:transformation, opts)
        xformation_3 = Factory(:transformation, opts.merge(:resource => resource_2))
        assert_equal 1, xformation_1.position
        assert_equal 2, xformation_2.position
        assert_equal 1, xformation_3.position
      end
    end
  end
end

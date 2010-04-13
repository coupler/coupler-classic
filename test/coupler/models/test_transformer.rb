require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestTransformer < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Transformer.superclass
        assert_equal :transformers, Transformer.table_name
      end

      def test_requires_name
        xformer = Factory.build(:transformer, :name => nil)
        assert !xformer.valid?
      end

      def test_requires_unique_name
        Factory.create(:transformer, :name => "foobar")
        xformer = Factory.build(:transformer, :name => "foobar")
        assert !xformer.valid?
      end

      def test_serializes_allowed_types
        Factory(:transformer, :name => "noop", :code => "value", :allowed_types => %w{string integer})
        xformer = Transformer[:name => "noop"]
        assert_equal %w{string integer}, xformer.allowed_types
      end

      def test_requires_allowed_types
        xformer = Factory.build(:transformer, :allowed_types => nil)
        assert !xformer.valid?
      end

      def test_requires_valid_allowed_types
        xformer = Factory.build(:transformer, :allowed_types => %w{blah})
        assert !xformer.valid?
      end

      def test_requires_result_type
        xformer = Factory.build(:transformer, :allowed_types => nil)
        assert !xformer.valid?
      end

      def test_requires_valid_result_type
        xformer = Factory.build(:transformer, :result_type => "blah")
        assert !xformer.valid?
      end

      def test_special_result_type
        xformer = Factory.build(:transformer, :result_type => "same")
        assert xformer.valid?
      end

      def test_requires_code
        xformer = Factory.build(:transformer, :code => nil)
        assert !xformer.valid?
      end

      def test_requires_parseable_code
        xformer = Factory.build(:transformer, :code => "foo(")
        assert !xformer.valid?
      end

      def test_no_op_transform
        xformer = Factory(:transformer, :name => "noop", :code => "value")
        original = {:id => 1, :first_name => "Golan", :last_name => "Trevize"}
        expected = original.dup
        result = xformer.transform(original, { :in => :first_name, :out => :first_name })
        assert_equal expected, result
      end

      def test_transform_new_field
        xformer = Factory(:transformer, :name => "downcaser", :code => "value.downcase")
        original = {:id => 1, :first_name => "Golan", :last_name => "Trevize"}
        expected = original.merge(:first_name_small => "golan")
        result = xformer.transform(original.dup, { :in => :first_name, :out => :first_name_small })
        assert_equal expected, result
      end

      def test_preview_downcaser
        xformer = Factory.build(:transformer, {
          :name => "downcaser", :code => "value.to_s.downcase",
          :allowed_types => %w{integer string datetime},
          :result_type => "string"
        })
        now = Time.now
        Timecop.freeze(now) do
          expected = {
            'integer'  => {:in => 123, :out => "123"},
            'string'   => {:in => "Test", :out => "test"},
            'datetime' => {:in => now, :out => now.to_s.downcase},
            'success'  => true
          }
          assert_equal expected, xformer.preview
        end
      end

      def test_preview_fails_if_invalid
        assert_nil Transformer.new.preview
      end

      def test_preview_code_error_returns_exception
        xformer = Factory.build(:transformer, {
          :name => "downcaser", :code => "value.downcase",
          :allowed_types => %w{integer string datetime},
          :result_type => "string"
        })
        now = Time.now
        Timecop.freeze(now) do
          expected = {
            'integer'  => {:in => 123, :out => Exception},
            'string'   => {:in => "Test", :out => "test"},
            'datetime' => {:in => now, :out => Exception},
            'success'  => false
          }
          assert expected === xformer.preview
        end
      end

      def test_requires_successful_preview
        xformer = Factory.build(:transformer, {
          :name => "downcaser", :code => "value.downcase",
          :allowed_types => %w{integer string datetime},
          :result_type => "string"
        })
        assert !xformer.valid?
      end
    end
  end
end
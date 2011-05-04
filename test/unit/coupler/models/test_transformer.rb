require 'helper'

module Coupler
  module Models
    class TestTransformer < Coupler::Test::UnitTest
      def new_transformer(attribs = {})
        values = {
          :name => "foo",
          :code => "value",
          :allowed_types => %w{string integer datetime},
          :result_type => 'same'
        }.update(attribs)
        Transformer.new(values)
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Transformer.superclass
        assert_equal :transformers, Transformer.table_name
      end

      test "requires name" do
        xformer = new_transformer(:name => nil)
        assert !xformer.valid?
      end

      test "requires unique name" do
        new_transformer(:name => "foobar").save!
        xformer = new_transformer(:name => "foobar")
        assert !xformer.valid?
      end

      test "serializes allowed types" do
        new_transformer.save!
        xformer = Transformer[:name => "foo"]
        assert_equal %w{string integer datetime}, xformer.allowed_types
      end

      test "requires allowed types" do
        xformer = new_transformer(:allowed_types => nil)
        assert !xformer.valid?
      end

      test "requires valid allowed types" do
        xformer = new_transformer(:allowed_types => %w{blah})
        assert !xformer.valid?
      end

      test "requires result type" do
        xformer = new_transformer(:result_type => nil)
        assert !xformer.valid?
      end

      test "requires valid result type" do
        xformer = new_transformer(:result_type => "blah")
        assert !xformer.valid?
      end

      test "special result type" do
        xformer = new_transformer(:result_type => "same")
        assert xformer.valid?
      end

      test "requires code" do
        xformer = new_transformer(:code => nil)
        assert !xformer.valid?
      end

      test "requires parseable code" do
        xformer = new_transformer(:code => "foo(")
        assert !xformer.valid?
      end

      test "no-op transform" do
        xformer = new_transformer.save!
        original = {:id => 1, :first_name => "Golan", :last_name => "Trevize"}
        expected = original.dup
        result = xformer.transform(original, { :in => :first_name, :out => :first_name })
        assert_equal expected, result
      end

      test "transform new field" do
        xformer = new_transformer(:code => "value.downcase", :allowed_types => %w{string}).save!
        original = {:id => 1, :first_name => "Golan", :last_name => "Trevize"}
        expected = original.merge(:first_name_small => "golan")
        result = xformer.transform(original.dup, { :in => :first_name, :out => :first_name_small })
        assert_equal expected, result
      end

      test "preview downcaser" do
        xformer = new_transformer({
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

      test "preview fails if invalid" do
        assert_nil Transformer.new.preview
      end

      test "preview code error returns exception" do
        xformer = new_transformer({
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

      test "requires successful preview" do
        xformer = new_transformer({
          :name => "downcaser", :code => "value.downcase",
          :allowed_types => %w{integer string datetime},
          :result_type => "string"
        })
        assert !xformer.valid?
      end

      test "requires correct result type" do
        xformer = new_transformer({
          :name => "stringify", :code => "value.to_i",
          :allowed_types => %w{integer string datetime},
          :result_type => "string"
        })
        assert !xformer.valid?
      end

      test "requires same result type" do
        xformer = new_transformer({
          :name => "stringify", :code => "value.to_i",
          :allowed_types => %w{integer string datetime},
          :result_type => "same"
        })
        assert !xformer.valid?
      end

      test "allows nil return value" do
        xformer = new_transformer({
          :name => "nullify", :code => "nil",
          :allowed_types => %w{integer string datetime},
          :result_type => "same"
        })
        assert xformer.valid?
      end

      test "field changes with no type changes" do
        field = stub('field', :id => 1)
        transformer = new_transformer({
          :allowed_types => %w{integer datetime string},
          :result_type => 'same', :code => 'value'
        }).save!
        assert_equal({ field.id => { } }, transformer.field_changes(field))
      end

      test "field changes to integer" do
        field = stub('field', :id => 1)
        transformer = new_transformer({
          :allowed_types => %w{integer datetime string},
          :result_type => 'integer', :code => 'value.to_i'
        }).save!
        assert_equal({ field.id => { :db_type => "int(11)", :type => :integer } }, transformer.field_changes(field))
      end

      #def test_should_handle_empty_values
        #pend
      #end
    end
  end
end

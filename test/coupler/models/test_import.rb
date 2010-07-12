require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestImport < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Models::Import.superclass
        assert_equal :imports, Import.table_name
      end

      def test_file_upload
        import = Models::Import.new(:data => fixture_file("people.csv"))
        assert_respond_to import.data, :current_path
      end

      def test_preview
        import = Models::Import.new(:data => fixture_file("people.csv"))
        preview = import.preview
        assert_kind_of Array, preview
        assert_equal 50, preview.length
        assert_kind_of FasterCSV::Row, preview[0]
      end

      def test_fields
        import = Models::Import.new(:data => {
          :tempfile => fixture_file("people.csv"), :filename => "huge.csv"
        })
        expected = [
          ["id", { :type => :integer, :primary_key => true }],
          ["first_name", { :type => :string }],
          ["last_name", { :type => :string }],
          ["age", { :type => :integer }]
        ]
        import.save
        assert_equal expected, import.fields
      end
    end
  end
end

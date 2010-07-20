require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestImport < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Models::Import.superclass
        assert_equal :imports, Import.table_name
      end

      def test_many_to_one_project
        assert_respond_to Models::Import.new, :project
      end

      def test_file_upload
        import = Models::Import.new(:data => fixture_file("people.csv"))
        assert_respond_to import.data, :current_path
      end

      def test_gets_name_from_csv_file
        import = Models::Import.create(:data => fixture_file("people.csv"))
        assert_equal "People", import.name
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

      def test_field_types=
        import = Models::Import.create(:data => {
          :tempfile => fixture_file("people.csv"), :filename => "huge.csv"
        })
        expected = [
          ["id", { :type => :integer, :primary_key => true }],
          ["first_name", { :type => :string }],
          ["last_name", { :type => :string }],
          ["age", { :type => :string }]
        ]
        import.field_types = { 'age' => { 'type' => 'string' } }
        assert_equal expected, import.fields
      end

      def test_primary_key=
        import = Models::Import.create(:data => { :tempfile => fixture_file("people.csv"), :filename => "huge.csv" })
        import.primary_key = "first_name"
        assert !import.fields.assoc("id")[1][:primary_key]
        assert import.fields.assoc("first_name")[1][:primary_key]
      end

      def test_import!
        project = Factory(:project)
        import = Models::Import.create(:data => fixture_file_upload("people.csv"), :project => project)
        import.import!

        project.local_database do |db|
          name = :"import_#{import.id}"
          assert db.tables.include?(name)
          schema = db.schema(name)
          assert_equal [:integer, true], schema.assoc(:id)[1].values_at(:type, :primary_key)
          assert_equal :string, schema.assoc(:first_name)[1][:type]
          assert_equal :string, schema.assoc(:last_name)[1][:type]
          assert_equal :integer, schema.assoc(:age)[1][:type]

          ds = db[name]
          assert_equal 50, ds.count
        end
      end
    end
  end
end

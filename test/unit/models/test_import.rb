require 'helper'

module Coupler
  module Models
    class TestImport < Coupler::Test::UnitTest
      def new_import(attribs = {})
        values = {
          :data => fixture_file_upload('people.csv'),
          :project => @project
        }.update(attribs)
        r = Import.new(values)
        r.stubs(:project_dataset).returns(stub({:all => [values[:project]]}))
        r
      end

      def setup
        super
        @project = stub('project', :pk => 456, :id => 456, :associations => {})
        @project.stubs(:resources_dataset).returns(stub {
          stubs(:filter).returns(self)
          stubs(:count).returns(0)
        })
      end

      test "sequel model" do
        assert_equal ::Sequel::Model, Models::Import.superclass
        assert_equal :imports, Import.table_name
      end

      test "many to one project" do
        assert_respond_to Models::Import.new, :project
      end

      test "gets name from original filename" do
        import = new_import
        assert_equal "People", import.name
      end

      test "preview with headers" do
        import = new_import
        preview = import.preview
        assert_kind_of Array, preview
        assert_equal 50, preview.length
        assert_kind_of Array, preview[0]
        assert_not_equal %w{id first_name last_name age}, preview[0]
      end

      test "discovers field names and types" do
        import = new_import
        expected_types = %w{integer string string integer}
        expected_names = %w{id first_name last_name age}
        assert_equal expected_names, import.field_names
        assert_equal expected_types, import.field_types
        assert_equal "id", import.primary_key_name
        assert import.has_headers
      end

      test "discover for csv with no headers" do
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("foo,bar,1,2,3\njunk,blah,4,5,6")
        tempfile.close
        import = new_import(:data => file_upload(tempfile.path))
        expected_types = %w{string string integer integer integer}
        assert_equal expected_types, import.field_types
        assert_nil import.field_names
        assert_nil import.primary_key_name
        assert !import.has_headers
      end

      test "requires field names" do
        import = new_import(:data => fixture_file_upload('no-headers.csv'))
        assert_nil import.field_names
        assert !import.valid?
      end

      test "requires primary key name" do
        import = new_import(:data => fixture_file_upload('no-headers.csv'))
        import.field_names = %w{id first_name last_name age}
        assert !import.valid?
      end

      test "requires valid primary key name" do
        import = new_import(:data => fixture_file_upload('no-headers.csv'))
        import.field_names = %w{id first_name last_name age}
        import.primary_key_name = "foo"
        assert !import.valid?
      end

      test "requires unique field names" do
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("id,foo,foo\n1,abc,def\n2,ghi,jkl\n3,mno,pqr")
        tempfile.close

        import = new_import(:data => file_upload(tempfile.path))
        assert !import.valid?
      end

      test "requires unused resource name" do
        import = new_import
        @project.resources_dataset.stubs(:count).returns(1)
        assert !import.valid?
      end

      test "dataset" do
        import = new_import.save!
        expected = mock('dataset')
        @project.expects(:local_database).yields(mock {
          expects(:[]).with(:"import_#{import.id}").returns(expected)
        })
        import.dataset do |actual|
          assert_equal expected, actual
        end
      end

      test "discover fields for csv with headers and varying number of fields" do
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("id,foo,bar\n1,2,3\n1,4,5\n1,6,7,\n123,456,789,,\n")
        tempfile.close

        import = new_import(:data => file_upload(tempfile.path))
        expected_types = %w{integer integer integer string string}
        expected_names = %w{id foo bar}
        assert_equal expected_names, import.field_names
        assert_equal expected_types, import.field_types
        assert_equal "id", import.primary_key_name
        assert import.has_headers
      end
    end
  end
end

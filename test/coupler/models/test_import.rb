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

      def test_gets_name_from_csv_file
        import = Factory.build(:import, :file_name => fixture_path("people.csv"))
        assert_equal "People", import.name
      end

      def test_preview_with_headers
        import = Factory.build(:import, :file_name => fixture_path("people.csv"))
        preview = import.preview
        assert_kind_of Array, preview
        assert_equal 50, preview.length
        assert_kind_of Array, preview[0]
        assert_not_equal %w{id first_name last_name age}, preview[0]
      end

      def test_discovers_field_names_and_types
        import = Factory.build(:import, :file_name => fixture_path("people.csv"))
        expected_types = %w{integer string string integer}
        expected_names = %w{id first_name last_name age}
        assert_equal expected_names, import.field_names
        assert_equal expected_types, import.field_types
        assert_equal "id", import.primary_key_name
        assert import.has_headers
      end

      def test_discover_for_csv_with_no_headers
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("foo,bar,1,2,3\njunk,blah,4,5,6")
        tempfile.close
        import = Factory.build(:import, :file_name => tempfile.path)
        expected_types = %w{string string integer integer integer}
        assert_equal expected_types, import.field_types
        assert_nil import.field_names
        assert_nil import.primary_key_name
        assert !import.has_headers
      end

      def test_import!
        project = Factory(:project)
        import = Factory(:import, :file_name => fixture_path("people.csv"), :project => project)
        now = Time.now
        Timecop.freeze(now) do
          assert import.import!
          assert_equal now, import.occurred_at
        end

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

      def test_requires_field_names
        import = Factory.build(:import, :file_name => fixture_path('no-headers.csv'))
        assert_nil import.field_names
        assert !import.valid?
      end

      def test_requires_primary_key_name
        import = Factory.build(:import, :file_name => fixture_path('no-headers.csv'))
        import.field_names = %w{id first_name last_name age}
        assert !import.valid?
      end

      def test_requires_valid_primary_key_name
        import = Factory.build(:import, :file_name => fixture_path('no-headers.csv'))
        import.field_names = %w{id first_name last_name age}
        import.primary_key_name = "foo"
        assert !import.valid?
      end

      def test_flags_duplicate_primary_keys
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("id,foo,bar\n1,abc,def\n2,ghi,jkl\n2,mno,pqr")
        tempfile.close

        project = Factory(:project)
        import = Factory(:import, :file_name => tempfile.path, :project => project)

        now = Time.at(Time.now.to_i)  # dumb usecs
        Timecop.freeze(now) do
          assert !import.import!
          assert import.has_duplicate_keys
          assert_equal now, import.occurred_at, "now: %d-%d; occurred_at: %d-%d" % [now.to_i, now.usec, import.occurred_at.to_i, import.occurred_at.usec]
        end

        project.local_database do |db|
          ds = db[:"import_#{import.id}"]
          assert ds.filter(:id => 2).select_map(:dup_key_count).all?
        end
      end

      def test_requires_unique_field_names
        tempfile = Tempfile.new('coupler-import')
        tempfile.write("id,foo,foo\n1,abc,def\n2,ghi,jkl\n3,mno,pqr")
        tempfile.close

        import = Factory.build(:import, :file_name => tempfile.path)
        assert !import.valid?
      end

      def test_requires_unused_resource_name
        project = Factory(:project)
        resource = Factory(:resource, :name => "Foo", :project => project)
        import = Factory.build(:import, :file_name => fixture_path('people.csv'), :name => "Foo", :project => project)
        assert !import.valid?
      end

      def test_dataset
        project = Factory(:project)
        import = Factory(:import, :project => project)
        import.import!
        project.local_database do |db|
          import.dataset do |ds|
            expected = db[:"import_#{import.id}"]
            assert_equal expected.first_source, ds.first_source
            assert_equal db.uri, ds.db.uri
          end
        end
      end
    end
  end
end

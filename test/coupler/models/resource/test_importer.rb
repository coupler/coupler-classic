require File.dirname(__FILE__) + "/../../../helper"

module Coupler
  module Models
    class Resource
      class TestImporter < Test::Unit::TestCase
        def test_data
          importer = Importer.new(fixture_file("people.csv"))
          data = importer.data
          assert_kind_of Array, data
          assert_equal 50, data.length
          assert_kind_of FasterCSV::Row, data[0]
        end

        def test_discover_columns
          importer = Importer.new(fixture_file("people.csv"))
          expected = [
            ["id", { :type => :integer, :primary_key => true }],
            ["first_name", { :type => :string }],
            ["last_name", { :type => :string }],
            ["age", { :type => :integer }]
          ]
          assert_equal expected, importer.columns
        end

        def test_filename
          importer = Importer.new(fixture_file("people.csv"))
          assert_equal "people.csv", importer.filename

          importer = Importer.new(fixture_file("people.csv"), "foobar.csv")
          assert_equal "foobar.csv", importer.filename
        end

        def test_file_size
          flunk
        end
      end
    end
  end
end

require 'helper'

module TestCoupler
  class TestFile < Test::Unit::TestCase
    def new_file(attribs = {})
      Coupler::File.new({
        :data => "foo,bar\n123,456",
        :filename => 'foo.csv',
        :format => 'csv'
      }.merge(attribs))
    end

    test "subclass of Sequel::Model" do
      assert_equal Sequel::Model, Coupler::File.superclass
    end

    test "requires data" do
      file = new_file(:data => nil)
      assert !file.valid?
    end

    test "requires filename" do
      file = new_file(:filename => nil)
      assert !file.valid?
    end

    test "requires format" do
      file = new_file(:format => nil)
      assert !file.valid?
    end

    test "requires valid format" do
      file = new_file(:format => 'foo')
      assert !file.valid?
    end

    test "csv with auto row_sep" do
      csv = stub('csv')
      CSV.expects(:new).with("foo,bar\n123,456", {
        :col_sep => ',', :row_sep => :auto, :quote_char => '"'
      }).returns(csv)
      file = new_file({
        :col_sep => ',',
        :row_sep => 'auto',
        :quote_char => '"'
      })
      assert_same csv, file.csv
    end

    test "csv with explicit row_sep" do
      csv = stub('csv')
      CSV.expects(:new).with("foo,bar\n123,456", {
        :col_sep => ',', :row_sep => "\n", :quote_char => '"'
      }).returns(csv)
      file = new_file({
        :col_sep => ',',
        :row_sep => "\n",
        :quote_char => '"'
      })
      assert_same csv, file.csv
    end

    test "default values for csv" do
      file = new_file(:format => 'csv')
      assert_equal ',', file.col_sep
      assert_equal 'auto', file.row_sep
      assert_equal '"', file.quote_char
    end
  end
end


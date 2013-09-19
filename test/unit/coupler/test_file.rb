require 'helper'

module TestCoupler
  class TestFile < Test::Unit::TestCase
    def new_file(attribs = {})
      Coupler::File.new({
        :data => "foo,bar\n123,456",
        :filename => 'foo.csv',
        :col_sep => ',',
        :row_sep => 'auto',
        :quote_char => '"'
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

    test "csv with auto row_sep" do
      csv = stub('csv')
      CSV.expects(:new).with("foo,bar\n123,456", {
        :col_sep => ',', :row_sep => :auto, :quote_char => '"'
      }).returns(csv)
      assert_same csv, new_file.csv
    end

    test "csv with explicit row_sep" do
      csv = stub('csv')
      CSV.expects(:new).with("foo,bar\n123,456", {
        :col_sep => ',', :row_sep => "\n", :quote_char => '"'
      }).returns(csv)
      file = new_file(:row_sep => "\n")
      assert_same csv, file.csv
    end
  end
end


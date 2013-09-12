require 'helper'

module TestCoupler
  class TestFile < Test::Unit::TestCase
    def new_file(attribs = {})
      Coupler::File.new({
        :data => "foo,bar\n123,456",
        :filename => 'foo.csv'
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
  end
end


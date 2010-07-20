require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestDataUploader < Test::Unit::TestCase
    def test_carrierwave_subclass
      assert_equal CarrierWave::Uploader::Base, DataUploader.superclass
    end

    def test_store_dir_same_as_upload_path
      Coupler::Config.expects(:get).with(:upload_path).returns("/path/to/uploads")
      uploader = DataUploader.new
      assert_equal "/path/to/uploads", uploader.store_dir
    end

    def test_filename_uniqueness
      uploader = DataUploader.new
      uploader.store!(fixture_file('people.csv'))
      assert_match /^[a-f0-9]+.csv$/, uploader.filename
    end
  end
end

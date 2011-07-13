require 'helper'

module CouplerUnitTests
  class TestDataUploader < Coupler::Test::UnitTest
    def test_carrierwave_subclass
      assert_equal CarrierWave::Uploader::Base, DataUploader.superclass
    end

    def test_store_dir_same_as_upload_path
      Coupler.expects(:upload_path).returns("/path/to/uploads")
      uploader = DataUploader.new
      assert_equal "/path/to/uploads", uploader.store_dir
    end

    def test_cache_dir_uses_upload_path
      Coupler.expects(:upload_path).returns("/path/to/uploads")
      uploader = DataUploader.new
      assert_equal "/path/to/uploads/tmp", uploader.cache_dir
    end

    def test_filename_uniqueness
      uploader = DataUploader.new
      uploader.store!(fixture_file_upload('people.csv'))
      assert_match /^people-[a-f0-9]+.csv$/, uploader.filename
    end
  end
end

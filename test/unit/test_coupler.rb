require 'helper'

module CouplerUnitTests
  class TestCoupler < Coupler::Test::UnitTest
    def test_db_path
      env = Coupler.environment
      expected = File.join(Coupler.data_path, 'db', env, 'ponies')
      assert_equal expected, Coupler.db_path("ponies")
    end

    def test_connection_string
      env = Coupler.environment
      expected = "jdbc:h2:#{File.join(Coupler.data_path, 'db', env, 'ponies')};IGNORECASE=TRUE"
      assert_equal expected, Coupler.connection_string("ponies")
    end

    def test_upload_path
      env = Coupler.environment
      expected = File.join(Coupler.data_path, 'uploads', env)
      assert_equal expected, Coupler.upload_path
    end

    def test_log_path
      expected = File.join(Coupler.data_path, 'log')
      assert_equal expected, Coupler.log_path
    end
  end
end

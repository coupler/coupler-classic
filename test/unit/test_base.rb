require 'helper'

module CouplerUnitTests
  class TestBase < Coupler::Test::UnitTest
    def test_subclasses_sinatra_base
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end

    def test_db_path
      env = Base.settings.environment
      begin
        Base.set :environment, :production
        expected = File.join(Base.settings.data_path, 'db', 'production', 'ponies')
        assert_equal expected, Base.db_path("ponies")
      ensure
        Base.set :environment, env
      end
    end

    def test_connection_string
      env = Base.settings.environment
      begin
        Base.set :environment, :production
        expected = "jdbc:h2:#{File.join(Base.settings.data_path, 'db', 'production', 'ponies')};IGNORECASE=TRUE"
        assert_equal expected, Base.connection_string("ponies")
      ensure
        Base.set :environment, env
      end
    end

    def test_upload_path
      env = Base.settings.environment
      begin
        Base.set :environment, :production
        expected = File.join(Base.settings.data_path, 'uploads', 'production')
        assert_equal expected, Base.upload_path
      ensure
        Base.set :environment, env
      end
    end

    def test_log_path
      expected = File.join(Base.settings.data_path, 'log')
      assert_equal expected, Base.log_path
    end
  end
end

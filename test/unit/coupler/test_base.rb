require File.dirname(__FILE__) + '/../helper'

module Coupler
  class TestBase < Test::Unit::TestCase
    def test_subclasses_sinatra_base
      assert_equal Sinatra::Base, Coupler::Base.superclass
    end

    def test_index_when_no_projects
      get "/"
      assert last_response.ok?
      assert_match /Getting Started/, last_response.body
    end

    def test_redirect_when_projects_exist
      project = Factory(:project)
      get "/"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
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
        expected = "jdbc:h2:#{File.join(Base.settings.data_path, 'db', 'production', 'ponies')}"
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

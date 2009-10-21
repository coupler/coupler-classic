require File.dirname(__FILE__) + "/../helper"

class Coupler::TestConfig < Test::Unit::TestCase
  def test_creates_config_database
    assert_kind_of Sequel::JDBC::Database, Coupler::Config

    server = Coupler::Server.instance
    assert_equal(
      server.connection_string("coupler_test", :create_database => true),
      Coupler::Config.uri
    )
    assert_equal [:projects, :resources, :transformations], Coupler::Config.tables
  end
end

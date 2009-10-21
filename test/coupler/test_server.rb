require File.dirname(__FILE__) + "/../helper"

class Coupler::TestServer < Test::Unit::TestCase
  def test_connection_string
    server = Coupler::Server.instance
    assert_equal(
      "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla",
      server.connection_string("ponies")
    )

    assert_equal(
      "jdbc:mysql://localhost:12345/ponies?user=coupler&password=cupla&createDatabaseIfNotExist=true",
      server.connection_string("ponies", :create_database => true)
    )
  end
end

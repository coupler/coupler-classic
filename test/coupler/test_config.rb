require File.dirname(__FILE__) + "/../helper"

class TestConfig < Test::Unit::TestCase
  def test_creates_config_database
    assert_kind_of Sequel::JDBC::Database, Coupler::Config

    filename = File.expand_path(File.dirname(__FILE__) + "/../../config/test.sqlite3")
    FileUtils.rm(filename, :force => true)
    assert_equal "jdbc:sqlite:#{filename}", Coupler::Config.uri
    assert_equal [:projects, :resources], Coupler::Config.tables
  end
end

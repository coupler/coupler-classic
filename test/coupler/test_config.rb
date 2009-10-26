require File.dirname(__FILE__) + "/../helper"

class Coupler::TestConfig < ActiveSupport::TestCase
  def setup
    @config = Coupler::Config.instance
  end

  def test_connection
    assert_kind_of Sequel::JDBC::Database, @config.__getobj__

    server = Coupler::Server.instance
    expected = server.connection_string("coupler_test", :create_database => true)
    assert_equal expected, @config.uri
  end

  def test_create_schema
    [:projects, :resources, :transformations].each do |name|
      @config.expects(:create_table).with(name)
    end
    @config.tables.each { |t| @config.drop_table(t) }
    @config.create_schema
  end
end

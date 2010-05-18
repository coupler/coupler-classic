require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Models
    class TestConnection < Test::Unit::TestCase
      def test_sequel_model
        assert_equal ::Sequel::Model, Connection.superclass
        assert_equal :connections, Connection.table_name
      end

      def test_one_to_many_resources
        assert_respond_to Connection.new, :resources
      end

      def test_requires_name
        connection = Factory.build(:connection, :name => nil)
        assert !connection.valid?

        connection.name = ""
        assert !connection.valid?
      end

      def test_requires_unique_name
        connection_1 = Factory.create(:connection, :name => "avast")
        connection_2 = Factory.build(:connection, :name => "avast")
        assert !connection_2.valid?
      end

      def test_required_unique_name_on_update
        connection_1 = Factory.create(:connection, :name => "avast")
        connection_2 = Factory.create(:connection, :name => "ahoy")
        connection_1.name = "ahoy"
        assert !connection_1.valid?, "Connection wasn't invalid"
      end

      def test_sets_slug_from_name
        connection = Factory(:connection, :name => 'Foo bar')
        assert_equal "foo_bar", connection.slug
      end

      def test_requires_unique_slug
        connection_1 = Factory(:connection, :slug => 'pants')
        connection_2 = Factory.build(:connection, :name => 'foo', :slug => 'pants')
        assert !connection_2.valid?

        connection_2.slug = "roflslam"
        assert connection_2.valid?
        connection_2.save

        connection_2.slug = "pants"
        assert !connection_2.valid?
      end

      def test_requires_valid_connection
        connection = Factory.build(:connection, :password => "foo")
        assert !connection.valid?, "Connection wasn't invalid"
      end

      def test_updating
        connection = Factory.create(:connection, :name => "avast")
        connection.save!
      end

      def test_mysql_database
        connection = Factory(:connection, {
          :name => "testing",
          :adapter => "mysql",
          :host => "localhost",
          :port => 12345,
          :username => "coupler",
          :password => "cupla",
        })
        connection.database('fake_data') do |database|
          assert_kind_of Sequel::JDBC::Database, database
          assert_match /zeroDateTimeBehavior=convertToNull/, database.uri
          assert database.test_connection
        end
      end
    end
  end
end

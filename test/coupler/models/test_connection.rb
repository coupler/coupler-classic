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
          :port => 3306,
        })
        connection.database('coupler_fake_data') do |database|
          assert_kind_of Sequel::JDBC::Database, database
          assert database.test_connection
        end
      end

      def test_embedded_h2_database
        connection = Factory(:connection, {
          :name => "testing",
          :adapter => "h2",
          :path => Base.settings.db_path('foo')
        })
        connection.database do |database|
          assert_kind_of Sequel::JDBC::Database, database
          assert database.test_connection
        end
      end

      def test_deletable_if_unused
        connection = Factory(:connection)
        assert connection.deletable?
      end

      def test_not_deletable_if_used
        connection = Factory(:connection)
        resource = Factory(:resource, :connection => connection)
        assert !connection.deletable?
      end

      def test_deleting_unused_connection
        connection = Factory(:connection)
        assert connection.destroy
        assert_nil Connection[connection.id]
      end

      def test_prevent_deleting_connection_in_use
        connection = Factory(:connection)
        resource = Factory(:resource, :connection => connection)
        assert !connection.destroy
        assert_not_nil Connection[connection.id]
      end

      def test_connection_limit
        pend
      end
    end
  end
end

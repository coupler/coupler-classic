require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestConnection < Coupler::Test::UnitTest
      test "sequel model" do
        assert_equal ::Sequel::Model, Connection.superclass
        assert_equal :connections, Connection.table_name
      end

      test "one to many resources" do
        assert_respond_to Connection.new, :resources
      end

      each_adapter do |adapter, _|
        adapter_test(adapter, "requires name") do
          connection = new_connection(adapter, :name => nil)
          assert !connection.valid?

          connection.name = ""
          assert !connection.valid?
        end

        adapter_test(adapter, "requires unique name") do
          connection_1 = new_connection(adapter, :name => 'foo')
          connection_1.save!
          connection_2 = new_connection(adapter, :name => 'foo')
          assert !connection_2.valid?
        end

        adapter_test(adapter, "requires unique name on update") do
          connection_1 = new_connection(adapter, :name => 'foo')
          connection_1.save!
          connection_2 = new_connection(adapter, :name => 'bar')
          connection_2.save!
          connection_1.name = "bar"
          assert !connection_1.valid?, "Connection wasn't invalid"
        end

        adapter_test(adapter, "sets slug from name") do
          connection = new_connection(adapter, :name => 'Foo bar')
          connection.save!
          assert_equal "foo_bar", connection.slug
        end

        adapter_test(adapter, "requires unique slug") do
          connection_1 = new_connection(adapter, :name => 'bar', :slug => 'bar')
          connection_1.save!
          connection_2 = new_connection(adapter, :name => 'foo', :slug => 'bar')
          assert !connection_2.valid?

          connection_2.slug = "baz"
          assert connection_2.valid?
          connection_2.save!

          connection_2.slug = "bar"
          assert !connection_2.valid?
        end

        adapter_test(adapter, 'database method') do
          connection = new_connection(adapter, :name => 'test')
          connection.save!
          connection.database do |database|
            assert_kind_of Sequel::JDBC::Database, database
            assert database.test_connection
          end
        end
      end

      adapter_test('h2', 'requires valid connection') do
        connection = new_connection('h2', :path => '/path/i/cant/create/foo/bar')
        assert !connection.valid?, "Connection wasn't invalid"
      end

      adapter_test('mysql', 'requires valid connection') do
        connection = new_connection('mysql', :password => 'incorrect_password')
        assert !connection.valid?, "Connection wasn't invalid"
      end

      test "deletable if unused" do
        connection = new_connection('h2', :name => 'foo')
        connection.save!
        connection.expects(:resources_dataset).returns(stub(:count => 0))
        assert connection.deletable?
      end

      test "not deletable if associated with resources" do
        connection = new_connection('h2', :name => 'foo')
        connection.save!
        connection.expects(:resources_dataset).returns(stub(:count => 1))
        assert !connection.deletable?
      end

      test "deleting unused connection" do
        connection = new_connection('h2', :name => 'foo')
        connection.save!
        connection.expects(:resources_dataset).returns(stub(:count => 0))
        assert connection.destroy
        assert_nil Connection[connection.id]
      end

      test "prevent deleting connection in use" do
        connection = new_connection('h2', :name => 'foo')
        connection.save!
        connection.expects(:resources_dataset).returns(stub(:count => 1))
        assert !connection.destroy
        assert_not_nil Connection[connection.id]
      end

      #def test_connection_limit
        #pend
      #end
    end
  end
end

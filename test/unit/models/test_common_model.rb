require 'helper'

module CouplerUnitTests
  module ModelTests
    class TestCommonModel < Coupler::Test::UnitTest
      def self.startup
        super
        db = Coupler::Database
        db.create_table!(:foos) do
          primary_key :id
          String :bar
          DateTime :created_at
          DateTime :updated_at
          DateTime :last_accessed_at
          Integer :version
        end
        db.create_table!(:foos_versions) do
          primary_key :id
          String :bar
          DateTime :created_at
          DateTime :updated_at
          DateTime :last_accessed_at
          Integer :version
          Integer :current_id
        end
      end

      def self.teardown
        db = Coupler::Database
        db.drop_table(:foos)
        super
      end

      def setup
        @klass = Class.new(Sequel::Model(:foos))
        @klass.send(:include, CommonModel)
      end

      test "timestamps on create" do
        now = Time.now
        Timecop.freeze(now) do
          foo = @klass.create(:bar => "bar")
          assert_equal now, foo.created_at
          assert_equal now, foo.updated_at
        end
      end

      test "timestamps on update" do
        foo = @klass.create(:bar => "bar")
        now = Time.now + 10
        Timecop.freeze(now) do
          foo.bar = "baz"
          foo.save!
          assert_equal now, foo.updated_at
        end
      end

      test "versioning new record" do
        foo = @klass.create(:bar => "bar")
        assert_equal 1, foo.version

        versions = Database[:foos_versions].filter(:current_id => foo.id)
        assert_equal 1, versions.count

        data = versions.first
        foo.values.each_pair do |key, value|
          next  if key == :id
          assert_equal value, data[key], "#{key} didn't match"
        end
      end

      test "versioning existing record" do
        foo = @klass.create(:bar => "bar")
        foo.update(:bar => "baz")
        assert_equal 2, foo.version

        versions = Database[:foos_versions].filter(:current_id => foo.id, :version => 2)
        assert_equal 1, versions.count

        data = versions.first
        foo.values.each_pair do |key, value|
          next  if key == :id
          if value.is_a?(Time)
            assert_equal value.to_i, data[key].to_i, "#{key} didn't match"
          else
            assert_equal value, data[key], "#{key} didn't match"
          end
        end
      end

      test "as_of_version" do
        foo = @klass.create(:bar => "bar")
        foo.update(:bar => "baz")

        hash = @klass.as_of_version(foo.id, 1)
        assert_equal "bar", hash[:bar]
      end

      test "as_of_time" do
        time = Time.now - 3600
        foo = nil
        Timecop.freeze(time) do
          foo = @klass.create(:bar => "bar")
        end
        foo.update(:bar => "baz")

        hash = @klass.as_of_time(foo.id, time + 1200)
        assert_equal "bar", hash[:bar]
      end

      test "touch!" do
        foo = @klass.create(:bar => 'bar')
        version = foo.version
        time = Time.now - 50
        Timecop.freeze(time) { foo.touch! }
        assert_equal time, foo.last_accessed_at
        assert_equal version, foo.version
      end

      test "recently_accessed" do
        now = Time.now
        foo_1 = @klass.create(:last_accessed_at => now - 50)
        foo_2 = @klass.create(:last_accessed_at => now - 10)
        foo_3 = @klass.create(:last_accessed_at => now - 30)
        foo_4 = @klass.create(:last_accessed_at => now - 20)
        assert_equal [foo_2, foo_4, foo_3], @klass.recently_accessed
      end
    end
  end
end

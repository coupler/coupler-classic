require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestScoreSet < Test::Unit::TestCase
    def setup
      super
      db { |inf| inf.execute("DROP DATABASE IF EXISTS score_sets") }
    end

    def teardown
      super
    end

    def db(&block)
      Sequel.connect(Config.connection_string("information_schema"), &block)
    end

    def test_create_makes_new_table
      Coupler::ScoreSet.create {|_| }

      actual = nil
      db { |inf| actual = inf[:TABLES].filter("TABLE_SCHEMA = ? AND TABLE_TYPE = ? AND TABLE_NAME = ?", "score_sets", "BASE TABLE", "1").count }
      assert_equal 1, actual
    end

    def test_create_yields_dataset
      Coupler::ScoreSet.create do |score_set|
        assert_kind_of Sequel::JDBC::MySQL::Dataset, score_set.__getobj__
      end
    end

    def test_create_increments_table_name
      Coupler::ScoreSet.create do |set|
        assert_equal :'1', set.first_source
      end
      Coupler::ScoreSet.create do |set|
        assert_equal :'2', set.first_source
      end
      db { |inf| inf.execute("DROP TABLE score_sets.2") }
      Coupler::ScoreSet.create do |set|
        assert_equal :'3', set.first_source
      end
    end

    def test_table_schema
      expected = [
        [:id, :integer],
        [:first_id, :integer],
        [:second_id, :integer],
        [:score, :integer]
      ]
      Coupler::ScoreSet.create do |set|
        schema = set.db.schema(:'1')
        expected.each do |(name, type)|
          info = schema.assoc(name)
          assert_not_nil info, "#{name} column doesn't exist"
          assert_equal type, info[1][:type], "#{name} columns isn't the right type"
        end
      end
    end

    def test_find_existing
      Coupler::ScoreSet.create {|_| }
      Coupler::ScoreSet.find(1) do |set|
        assert_equal :'1', set.first_source
      end
    end

    def test_find_nonexisting
      Coupler::ScoreSet.find(1337) do |set|
        assert_nil set
      end
    end

    def test_id
      Coupler::ScoreSet.create do |set|
        assert_equal 1, set.id
      end
    end

    def test_insert_or_update
      Coupler::ScoreSet.create do |set|
        filtered = set.filter(:first_id => 1, :second_id => 2)
        set.insert_or_update(:first_id => 1, :second_id => 2, :score => 10)
        assert_equal 10, filtered.first[:score]
        set.insert_or_update(:first_id => 1, :second_id => 2, :score => 10)
        assert_equal 20, filtered.first[:score]
      end
    end
  end
end

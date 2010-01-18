require File.dirname(__FILE__) + "/../helper"

module Coupler
  class TestScores < ActiveSupport::TestCase
    def setup
      @server = Coupler::Server.instance
      @inf = Sequel.connect(@server.connection_string("information_schema"))
      @inf.execute("DROP DATABASE IF EXISTS score_sets")
    end

    def test_create_makes_new_table
      score_set = Coupler::ScoreSet.create
      assert_equal 1, @inf[:TABLES].filter("TABLE_SCHEMA = ? AND TABLE_TYPE = ? AND TABLE_NAME = ?", "score_sets", "BASE TABLE", "1").count
    end

    def test_create_returns_dataset
      score_set = Coupler::ScoreSet.create
      assert_kind_of Sequel::JDBC::MySQL::Dataset, score_set.__getobj__
    end

    def test_create_increments_table_name
      assert_equal :'1', Coupler::ScoreSet.create.first_source
      assert_equal :'2', Coupler::ScoreSet.create.first_source
      @inf.execute("DROP TABLE score_sets.2")
      assert_equal :'3', Coupler::ScoreSet.create.first_source
    end

    def test_table_schema
      score_set = Coupler::ScoreSet.create
      schema = score_set.db.schema(:'1')
      expected = [
        [:id, :integer],
        [:first_id, :integer],
        [:second_id, :integer],
        [:score, :integer]
      ]
      expected.each do |(name, type)|
        info = schema.assoc(name)
        assert_not_nil info, "#{name} column doesn't exist"
        assert_equal type, info[1][:type], "#{name} columns isn't the right type"
      end
    end

    def test_find_existing
      Coupler::ScoreSet.create
      score_set = Coupler::ScoreSet.find(1)
      assert_equal :'1', score_set.first_source
    end

    def test_find_nonexisting
      score_set = Coupler::ScoreSet.find(1337)
      assert_nil score_set
    end
  end
end

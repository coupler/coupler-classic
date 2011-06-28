require 'helper'

module CouplerUnitTests
  class TestImportBuffer < Coupler::Test::UnitTest
    include Coupler

    def setup
      super
      @database = stub('database', :run => nil)
      @dataset = stub('dataset', {
        :insert_sql => "INSERT INTO \"FOO\" (\"BAR\") VALUES",
        :db => @database,
        :first_source_alias => :foo
      })
    end

    test "single insert" do
      @dataset.expects(:insert_sql).with([:bar], Sequel::LiteralString.new("VALUES")).returns("INSERT INTO \"FOO\" (\"BAR\") VALUES")
      @dataset.expects(:literal).with([123]).returns("(123)")
      @database.expects(:run).with("INSERT INTO \"FOO\" (\"BAR\") VALUES (123)")
      buffer = ImportBuffer.new([:bar], @dataset)
      buffer.add({:bar => 123})
      buffer.flush
    end

    test "multiple insert" do
      @dataset.expects(:literal).with([123]).returns("(123)")
      @dataset.expects(:literal).with([456]).returns("(456)")
      @database.expects(:run).with("INSERT INTO \"FOO\" (\"BAR\") VALUES (123), (456)")
      buffer = ImportBuffer.new([:bar], @dataset)
      buffer.add({:bar => 123})
      buffer.add({:bar => 456})
      buffer.flush
    end

    test "max query size / auto-flush" do
      size = ImportBuffer::MAX_QUERY_SIZE - 50
      str = "x" * size

      # bar is a string this time
      @dataset.expects(:literal).twice.with([str]).returns("(#{str})")
      @database.expects(:run).twice
      buffer = ImportBuffer.new([:bar], @dataset)
      buffer.add({:bar => str})
      buffer.add({:bar => str})
      buffer.flush
    end
  end
end

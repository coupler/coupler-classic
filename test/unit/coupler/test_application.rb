require 'helper'

module TestCoupler
  class TestApplication < Test::Unit::TestCase
    include Rack::Test::Methods
    include XhrHelper

    def app
      Coupler::Application
    end

    test "index" do
      get '/'
      assert last_response.ok?
    end

    test "files index" do
      file = stub('file', {
        :filename => 'foo.txt', :col_sep => ',',
        :row_sep => 'auto', :quote_char => '"'
      })
      Coupler::File.expects(:all).returns([file])
      get '/files'
      assert last_response.ok?
    end

    test "file upload" do
      Dir.mktmpdir do |dir|
        fn = File.join(dir, 'foo.txt')
        File.open(fn, 'w') { |f| f.puts("foo") }
        upload = Rack::Test::UploadedFile.new(fn, 'text/plain')

        file = stub('file')
        Coupler::File.expects(:new).returns(file)
        file.expects(:set_only).with({
          'data' => "foo\n", 'filename' => 'foo.txt',
          'col_sep' => ',', 'row_sep' => 'auto', 'quote_char' => '"'
        }, :data, :filename, :col_sep, :row_sep, :quote_char)
        file.expects(:valid?).returns(true)
        file.expects(:save).returns(true)
        file.stubs(:id).returns(1)

        post '/files', 'file' => {
          'upload' => upload, 'col_sep' => ',', 'row_sep' => 'auto',
          'quote_char' => '"'
        }
        assert last_response.redirect?
        assert_equal "http://example.org/files/1/edit", last_response['location']
      end
    end

    test "bad file upload" do
      Dir.mktmpdir do |dir|
        fn = File.join(dir, 'foo.txt')
        File.open(fn, 'w') { |f| f.puts("foo") }
        upload = Rack::Test::UploadedFile.new(fn, 'text/plain')

        file = stub('file')
        Coupler::File.expects(:new).returns(file)
        file.expects(:set_only).with({
          'col_sep' => ',', 'row_sep' => 'auto', 'quote_char' => '"'
        }, :data, :filename, :col_sep, :row_sep, :quote_char)
        file.expects(:valid?).returns(false)
        file.expects(:save).never

        post '/files', 'file' => {
          'col_sep' => ',', 'row_sep' => 'auto', 'quote_char' => '"'
        }
        assert last_response.redirect?
        assert_equal "http://example.org/files", last_response['location']
      end
    end

    test "edit file" do
      csv = stub('csv', :shift => %w{foo bar})
      csv.stubs(:each).yields(%w{123 456})
      file = stub('file', {
        :id => 1, :filename => 'foo.csv', :col_sep => ',',
        :row_sep => 'auto', :quote_char => '"', :csv => csv
      })
      Coupler::File.expects(:[]).with(:id => '1').returns(file)

      get '/files/1/edit'
      assert last_response.ok?
    end

    test "file table with default settings" do
      csv = stub('csv', :shift => %w{foo bar})
      csv.stubs(:each).yields(%w{123 456})
      file = stub('file', {
        :data => "foo,bar\n123,456\n", :col_sep => ',', :row_sep => 'auto',
        :quote_char => '"', :csv => csv
      })
      Coupler::File.expects(:[]).with(:id => '1').returns(file)

      get '/files/1/table'
      assert last_response.ok?
    end

    test "file table with explicit options" do
      csv = stub('csv', :shift => %w{foo bar})
      csv.stubs(:each).yields(%w{123 456})
      file = stub('file', {
        :data => "foo,bar\n123,456\n", :col_sep => ',', :row_sep => 'auto',
        :quote_char => '"', :csv => csv
      })
      Coupler::File.expects(:[]).with(:id => '1').returns(file)
      file.expects(:col_sep=).with("\t")
      file.expects(:row_sep=).with("\n")
      file.expects(:quote_char=).with("'")

      get '/files/1/table', {
        'col_sep' => "\t", 'row_sep' => "\n", 'quote_char' => "'"
      }
      assert last_response.ok?
    end

    test "file table with parse error" do
      csv = stub('csv')
      csv.stubs(:shift).raises(CSV::MalformedCSVError)
      file = stub('file', {
        :data => "foo,bar\n123,456\n", :col_sep => ',', :row_sep => 'auto',
        :quote_char => '"', :csv => csv
      })
      Coupler::File.expects(:[]).with(:id => '1').returns(file)

      get '/files/1/table'
      assert last_response.ok?
    end

    test "update file attributes" do
      file = stub('file')
      Coupler::File.expects(:[]).with(:id => '1').returns(file)
      file.expects(:set_only).with({
        'col_sep' => ',', 'row_sep' => 'auto', 'quote_char' => '"'
      }, :col_sep, :row_sep, :quote_char).returns(file)
      file.expects(:valid?).returns(true)
      file.expects(:save).returns(true)

      post '/files/1', 'file' => {
        'col_sep' => ',', 'row_sep' => 'auto', 'quote_char' => '"'
      }
      assert last_response.redirect?
      assert_equal "http://example.org/files", last_response['location']
    end
  end
end

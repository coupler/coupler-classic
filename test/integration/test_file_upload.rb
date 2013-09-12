require 'helper'

class TestFileUpload < Test::Unit::TestCase
  include IntegrationHelper

  test "uploading a text file" do
    Dir.mktmpdir do |dir|
      fn = File.join(dir, 'foo.txt')
      File.open(fn, 'w') { |f| f.puts('foo') }

      assert_equal 0, Coupler::File.count
      visit('/files')
      attach_file('file[upload]', fn)
      find('input[type="submit"]').click
      assert_equal 1, Coupler::File.count
    end
  end
end

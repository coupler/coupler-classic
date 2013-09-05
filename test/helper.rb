require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'mocha/setup'
require 'rack/test'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'coupler'

class SequenceHelper
  def initialize(name)
    @seq = sequence(name)
  end

  def <<(expectation)
    expectation.in_sequence(@seq)
  end
end

module XhrHelper
  def xhr(path, params={})
    verb = params.delete(:as) || :get
    send(verb, path, params, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest")
  end
end

class Test::Unit::TestCase
  alias_method :run_without_transactions, :run

  def run(*args, &block)
    result = nil
    Sequel::Model.db.transaction(:rollback => :always) do
      result = run_without_transactions(*args, &block)
    end
    result
  end
end

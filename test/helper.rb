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
require 'capybara/poltergeist'
require 'database_cleaner'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'coupler'

Capybara.javascript_driver = :poltergeist
Capybara.app = Coupler::Application

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

module IntegrationHelper
  include Capybara::DSL

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
    super
  end
end

DatabaseCleaner.strategy = :truncation
class Test::Unit::TestCase
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end

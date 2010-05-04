require 'autowatchr'

ENV['COUPLER_ENV'] = "test"
Autowatchr.new(self) do |config|
  config.ruby = "jruby --debug"
  config.run_suite = false
end

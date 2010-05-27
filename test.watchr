require 'autowatchr'

ENV['COUPLER_ENV'] = "test"
Autowatchr.new(self) do |config|
  config.ruby = "jruby --debug -X+O"
  config.run_suite = false
end

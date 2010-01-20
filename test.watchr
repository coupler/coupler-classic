require 'autowatchr'

ENV['COUPLER_ENV'] = "test"
Autowatchr.new(self) do |config|
  config.ruby = "jruby -J-Djruby.objectspace.enabled=true"
end

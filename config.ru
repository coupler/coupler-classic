require './application'
use Rack::Session::Cookie, secret: SecureRandom.hex(64)
run Coupler::Application.new

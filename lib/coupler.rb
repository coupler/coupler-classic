require 'sinatra/base'
require 'erb'

class Coupler < Sinatra::Base
  get "/resources/new" do
    erb :new_resource
  end
end

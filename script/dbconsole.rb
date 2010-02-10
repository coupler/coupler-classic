require 'rubygems'
require 'lib/coupler/server'

server = Coupler::Server.instance
server.console || puts("Coupler's database server isn't running.  Start it with `rake db:console'")

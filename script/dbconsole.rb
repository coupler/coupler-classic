require 'lib/coupler'

server = Coupler::Server.instance
server.console || puts("Coupler's database server isn't running.  Start it with `rake db:console'")

module Coupler
  CONFIG_PATH = File.dirname(__FILE__) + "/../../config/"
  COUPLER_ENV = ENV['COUPLER_ENV'] || 'development'

  Config = Sequel.connect('jdbc:sqlite:' +
    File.expand_path(File.dirname(__FILE__) + "/../../config/#{COUPLER_ENV}.sqlite3"))

  if Config.tables.empty?
    Config.create_table :databases do
      primary_key :id
      String :name
      String :adapter
      String :host
      Integer :port
      String :username
      String :password
      String :dbname
    end
  end
end

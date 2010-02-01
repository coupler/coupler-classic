namespace :db do
  task :environment do
    require File.join(File.dirname(__FILE__), "..", "lib", "coupler", "server")
  end

  desc "Obliterate the local database"
  task :nuke => :stop do
    confirm("This will completely obliterate the local database.")

    require 'fileutils'
    FileUtils.rm_rf(Dir.glob(File.join(Coupler::Config[:data_path], "db", "*")), :verbose => true)
  end

  desc "Bootstrap the server schema"
  task :bootstrap => [:start, 'coupler:environment'] do
    confirm("This will delete any existing configuration data.") if ENV['COUPLER_ENV'] != "test"

    server = Coupler::Server.instance
    server.start

    database = Coupler::Database.instance
    database.tables.each { |t| database.drop_table(t) }
    database.create_schema
  end

  desc "Start server daemon"
  task :start => :environment do
    server = Coupler::Server.instance
    server.start
  end

  desc "Stop server daemon"
  task :stop => :environment do
    server = Coupler::Server.instance
    server.shutdown
  end

  desc "Check server status"
  task :status => :environment do
    server = Coupler::Server.instance
    puts server.is_running? ? "Server is running." : "Server is not running."
  end

  begin
    require 'forgery'
    require 'sequel'
    desc "Create database with fake data"
    task :fake => [:start, 'coupler:environment'] do
      db = Sequel.connect(Coupler::Config.connection_string("fake_data", :create_database => true))
      db.tables.each { |t| db.drop_table(t) }
      db.create_table :people do
        primary_key :id
        String :first_name
        String :last_name
      end
      people = db[:people]

      num = ENV.has_key?('NUM') ? ENV['NUM'].to_i : 50
      num.times do |i|
        people.insert({
          :first_name => Forgery(:name).first_name,
          :last_name  => Forgery(:name).last_name
        })
      end
    end
  rescue LoadError
    task :prepare do
      abort "Forgery and/or Sequel is not available. In order to run this task, you must: sudo gem install forgery sequel"
    end
  end
end

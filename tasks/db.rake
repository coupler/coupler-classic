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
    require 'test/factories'
    confirm("This will delete any existing configuration data.") if ENV['COUPLER_ENV'] != "test"

    server = Coupler::Server.instance
    server.start

    database = Coupler::Database.instance
    database.tables.each { |t| database.drop_table(t) }
    database.create_schema

    project = Factory(:project)
    resource = Factory(:resource, :project => project)
    scenario = Factory(:scenario, :project => project, :resource_1 => resource)
    matcher = Factory(:matcher, :scenario => scenario)
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
      db.create_table :pets do
        primary_key :id
        String :name
        String :owner_first_name
        String :owner_last_name
      end
      db.create_table :no_primary_key do
        String :foo
        String :bar
      end
      db.create_table :two_primary_keys do
        String :foo
        String :bar
        primary_key [:foo, :bar]
      end
      db.execute("CREATE TABLE string_primary_key (foo VARCHAR(255), PRIMARY KEY(foo))")
      db.create_table :avast_ye do
        primary_key :arrr
        String :scurvy_dog
      end

      people = db[:people]
      pets = db[:pets]

      num = ENV.has_key?('NUM') ? ENV['NUM'].to_i : 50
      num.times do |i|
        person = {
          :first_name => Forgery(:name).first_name,
          :last_name  => Forgery(:name).last_name
        }
        pet = {
          :name => Forgery(:name).first_name,
          :owner_first_name => person[:first_name],
          :owner_last_name => person[:last_name]
        }
        people.insert(person)
        pets.insert(pet)
      end

      pirates = db[:avast_ye]
      pirates.insert(:scurvy_dog => "Pete")
      pirates.insert(:scurvy_dog => "Westley")
    end
  rescue LoadError
    task :prepare do
      abort "Forgery and/or Sequel is not available. In order to run this task, you must: sudo gem install forgery sequel"
    end
  end
end

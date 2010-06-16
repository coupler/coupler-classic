namespace :db do
  desc "Obliterate the local database"
  task :nuke => :stop do
    confirm("This will completely obliterate the local database.")

    require 'fileutils'
    dirs = Dir.glob(File.join(Coupler::Config.get(:data_path), "db", "*"))
    FileUtils.rm_rf(dirs.reject { |d| d =~ /migrate$/ }, :verbose => true)
  end

  desc "Purge the database"
  task :purge => [:start, :environment] do
    database = Coupler::Database.instance
    database.tables.each { |t| database.drop_table(t) }
  end

  desc "Run migrations"
  task :migrate => [:start, :environment] do
    version = ENV['VERSION']
    Coupler::Database.instance.migrate!(version ? version.to_i : nil)
  end

  namespace :migrate do
    desc "Reset the database"
    task :reset => ['db:purge', 'db:migrate']
  end

  desc "Roll the database back a version"
  task :rollback => [:start, :environment] do
    Coupler::Database.instance.rollback!
  end

  desc "Reset and bootstrap the database"
  task :bootstrap => [:start, :environment] do
    require 'test/factories'
    confirm("This will delete any existing configuration data.") if ENV['COUPLER_ENV'] != "test"

    Rake::Task["db:migrate:reset"].invoke

    project = Factory(:project, :name => "Fake")
    connection = Factory(:connection, :name => "Fake")
    resource = Factory(:resource, :name => "People", :project => project, :connection => connection)
    scenario = Factory(:scenario, :name => "First to last", :project => project, :resource_1 => resource)
    matcher = Factory(:matcher, {
      :scenario => scenario,
      :comparisons_attributes => [{
        :lhs_type => 'field', :lhs_value => resource.fields_dataset[:name => 'first_name'].id, :lhs_which => 1,
        :rhs_type => 'field', :rhs_value => resource.fields_dataset[:name => 'last_name'].id,  :rhs_which => 2,
        :operator => 'equals'
      }]
    })
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
    task :fake => [:start, :environment] do
      db = Sequel.connect(Coupler::Config.connection_string("fake_data", :create_database => true))
      db.tables.each { |t| db.drop_table(t) }
      db.create_table :people do
        primary_key :id
        String :first_name
        String :last_name
        Integer :age
        index :first_name
        index :last_name
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
      db.create_table :lots_of_nulls do
        primary_key :id
        String :empty
      end

      people = db[:people]
      pets = db[:pets]

      num = ENV.has_key?('NUM') ? ENV['NUM'].to_i : 50
      person_records = []
      pet_records = []
      num.times do |i|
        person = [ Forgery(:name).first_name, Forgery(:name).last_name, rand(30) + 20 ]
        pet = [ Forgery(:name).first_name, person[0], person[1] ]

        person_records << person
        pet_records << pet
        if i % 10000 == 0
          people.import([:first_name, :last_name, :age], person_records)
          pets.import([:name, :owner_first_name, :owner_last_name], pet_records)
          person_records.clear
          pet_records.clear
        end
      end
      people.import([:first_name, :last_name, :age], person_records)
      pets.import([:name, :owner_first_name, :owner_last_name], pet_records)

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

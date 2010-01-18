module Coupler
  class ScoreSet < Delegator
    def self.database
      connection_string = Coupler::Server.instance.connection_string('score_sets', :create_database => true)
      database = Sequel.connect(connection_string, :loggers => [Coupler.logger])
      if database.tables.empty?
        database.create_table(:housekeeping) do
          Integer :last_table
        end
        database[:housekeeping].insert(:last_table => 0)
      end
      database
    end

    def self.create
      database = self.database
      housekeeping = database[:housekeeping]

      new_table_num = housekeeping.first[:last_table] + 1
      new_table_sym = new_table_num.to_s.to_sym
      database.create_table(new_table_sym) do
        primary_key :id
        Integer :first_id
        Integer :second_id
        Integer :score
      end
      housekeeping.update(:last_table => new_table_num)

      new(database[new_table_sym])
    end

    def self.find(id)
      database = self.database

      table_sym = id.is_a?(Symbol) ? id : id.to_s.to_sym
      if database.tables.include?(table_sym)
        new(database[table_sym])
      else
        nil
      end
    end

    def initialize(dataset)
      @dataset = dataset
    end
    private :initialize

    def __getobj__
      @dataset
    end
  end
end

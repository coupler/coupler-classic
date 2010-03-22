module Coupler
  class ScoreSet < Delegator
    def self.database
      connection_string = Config.connection_string('score_sets', :create_database => true)
      Sequel.connect(connection_string, :loggers => [Coupler::Logger.instance]) do |database|
        if database.tables.empty?
          database.create_table(:housekeeping) do
            Integer :last_table
          end
          database[:housekeeping].insert(:last_table => 0)
        end
        yield database
      end
    end

    def self.create
      self.database do |database|
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

        score_set = new(new_table_num, database[new_table_sym])
        yield score_set
      end
    end

    def self.find(id)
      self.database do |database|
        table_sym = id.is_a?(Symbol) ? id : id.to_s.to_sym
        score_set = if database.tables.include?(table_sym)
                      new(id.to_i, database[table_sym])
                    else
                      nil
                    end
        yield score_set
      end
    end

    attr_reader :id
    def initialize(id, dataset)
      @id = id
      @dataset = dataset
    end
    private :initialize

    def __getobj__
      @dataset
    end

    def insert_or_update(options)
      first_id  = options[:first_id]
      second_id = options[:second_id]
      score     = options[:score]

      filtered = @dataset.filter(:first_id => first_id, :second_id => second_id)
      if filtered.count == 0
        @dataset.insert(:first_id => first_id, :second_id => second_id, :score => score)
      else
        filtered.update("score = score + #{score.to_i}")
      end
    end
  end
end

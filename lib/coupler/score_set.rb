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

    def self.create(type_1 = :integer, type_2 = :integer)
      self.database do |database|
        type_1, type_2 = [type_1, type_2].collect do |type|
          case type
          when :integer, 'integer' then Integer
          when :string,  'string'  then String
          else type
          end
        end

        housekeeping = database[:housekeeping]
        new_table_num = housekeeping.first[:last_table] + 1
        new_table_sym = new_table_num.to_s.to_sym
        database.create_table(new_table_sym) do
          primary_key :id
          columns.push({:name => :first_id, :type => type_1})
          columns.push({:name => :second_id, :type => type_2})
          Integer :score
          Integer :matcher_id
          TrueClass :transitive
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
      super(dataset)
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

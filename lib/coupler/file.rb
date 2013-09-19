module Coupler
  class File < Sequel::Model
    FORMAT_TYPES = %w{csv other}

    def format=(format)
      super

      case format
      when 'csv'
        self.col_sep = ','    if col_sep.nil?
        self.row_sep = 'auto' if row_sep.nil?
        self.quote_char = '"' if quote_char.nil?
      end
    end

    def csv
      CSV.new(data, {
        :col_sep => col_sep,
        :row_sep => row_sep == 'auto' ? :auto : row_sep,
        :quote_char => quote_char
      })
    end

    protected

    def validate
      super
      validates_presence [:data, :filename, :format]
      validates_includes FORMAT_TYPES, :format
    end
  end
end

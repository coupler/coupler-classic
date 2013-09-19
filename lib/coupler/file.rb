module Coupler
  class File < Sequel::Model
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
      validates_presence [:data, :filename]
    end
  end
end

module Coupler
  class File < Sequel::Model
    protected

    def validate
      super
      validates_presence [:data, :filename]
    end
  end
end

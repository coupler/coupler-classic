module Coupler
  class Resource < Sequel::Model
    many_to_one :database
  end
end

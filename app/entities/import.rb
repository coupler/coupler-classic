module Coupler
  class Import
    include Lotus::Entity

    self.attributes = :path, :filetype
  end
end

module Coupler
  class Project
    include Lotus::Entity

    self.attributes = :name, :slug, :description, :created_at, :updated_at, :last_accessed_at
  end
end

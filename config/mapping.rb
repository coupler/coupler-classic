collection :projects do
  entity Coupler::Project

  attribute :id, Integer
  attribute :name, String
  attribute :slug, String
  attribute :description, String
  attribute :created_at, DateTime
  attribute :updated_at, DateTime
  attribute :last_accessed_at, DateTime
end

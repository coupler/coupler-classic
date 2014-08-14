require 'spec_helper'

describe Project do
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:slug) }
  it { is_expected.to respond_to(:description) }
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }
  it { is_expected.to respond_to(:last_accessed_at) }
end

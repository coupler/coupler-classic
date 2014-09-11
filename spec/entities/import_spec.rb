require 'spec_helper'

describe Import do
  it { should respond_to(:path) }
  it { should respond_to(:filetype) }
end

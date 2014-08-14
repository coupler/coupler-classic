require 'spec_helper'

describe HomeController do
  describe HomeController::Index do
    it 'should be successful' do
      status, headers, body = subject.call({})
      expect(status).to eq(200)
    end
  end
end

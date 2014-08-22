require 'spec_helper'

describe ProjectsController do
  describe ProjectsController::New do
    it 'should expose new user' do
      project = double('project')
      expect(Project).to receive(:new).and_return(project)
      subject.call({})
      expect(subject.exposures[:project]).to eql(project)
    end
  end
end

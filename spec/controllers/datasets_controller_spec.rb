require 'spec_helper'

describe DatasetsController do
  describe DatasetsController::New do
    let(:params) { {project_id: 123} }
    let(:project) { double('project') }

    before do
      allow(ProjectRepository).to receive(:find).with(123).and_return(project)
    end

    it 'should expose project' do
      expect(ProjectRepository).to receive(:find).with(123).and_return(project)
      subject.call(params)
      expect(subject.exposures[:project]).to eql(project)
    end

    it 'should return success' do
      status, headers, body = subject.call(params)
      expect(status).to eq(200)
    end
  end
end

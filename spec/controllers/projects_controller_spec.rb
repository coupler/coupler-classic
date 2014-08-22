require 'spec_helper'

describe ProjectsController do
  let(:project) { double('project') }

  describe ProjectsController::New do
    it 'should expose new user' do
      expect(Project).to receive(:new).and_return(project)
      subject.call({})
      expect(subject.exposures[:project]).to eql(project)
    end
  end

  describe ProjectsController::Create do
    let(:params) { {name: 'Foo', description: 'This project is foo!'} }

    context 'with valid parameters' do
      it 'should create project' do
        expect(Project).to receive(:new).with(params).and_return(project)
        expect(ProjectRepository).to receive(:create).with(project)
        expect(project).to receive(:id).and_return(1)

        status, headers, body = subject.call(params)
        expect(status).to eq(302)
        expect(headers['Location']).to eq('/projects/1')
      end
    end

    context 'with invalid parameters' do
      let(:params) { super().merge({name: ''}) }

      it 'should expose project' do
        expect(Project).to receive(:new).with(params).and_return(project)
        expect(ProjectRepository).to_not receive(:create).with(project)

        status, headers, body = subject.call(params)
        expect(status).to eq(200)
      end
    end
  end
end

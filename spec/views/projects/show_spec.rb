require 'spec_helper'

describe Projects::Show do
  let(:project) { double('project') }
  let(:presenter) { double('presenter') }
  let(:template) { double('template') }
  subject(:view) { Projects::Show.new(template, {project: project}) }

  before do
    allow(ProjectPresenter).to receive(:new).with(project).and_return(presenter)
  end

  describe '#project' do
    it 'should return presenter' do
      expect(ProjectPresenter).to receive(:new).with(project).and_return(presenter)
      expect(view.project).to eql(presenter)
    end
  end
end

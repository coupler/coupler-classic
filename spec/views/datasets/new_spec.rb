require 'spec_helper'

describe Datasets::New do
  let(:project) { double('project') }
  let(:project_presenter) { double('project presenter') }
  let(:import) { double('import') }
  let(:import_presenter) { double('import presenter') }
  let(:template) { double('template') }
  subject(:view) { Datasets::New.new(template, {project: project, import: import}) }

  before do
    allow(ProjectPresenter).to receive(:new).with(project).and_return(project_presenter)
    allow(ImportPresenter).to receive(:new).with(import).and_return(import_presenter)
  end

  describe "#project" do
    it 'should return presenter' do
      expect(view.project).to eql(project_presenter)
    end
  end

  describe "#import" do
    it 'should return presenter' do
      expect(view.import).to eql(import_presenter)
    end
  end

  describe '#import_form' do
    let(:form) { double('form') }

    it 'should return import form' do
      expect(Forme::Form).to receive(:new).with(import_presenter).and_return(form)
      expect(view.import_form).to eql(form)
    end
  end
end

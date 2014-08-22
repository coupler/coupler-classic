require 'spec_helper'

describe ProjectPresenter do
  let(:project) { double('project', name: 'foo', description: 'bar') }
  subject(:presenter) { ProjectPresenter.new(project) }

  describe '#forme_input' do
    let(:form) { double('form') }
    let(:input) { double('input') }

    describe 'when field is :name' do
      it 'should create text field' do
        expect(Forme::Input).to receive(:new).with(form, :text, {
          key: :name, value: 'foo', label: 'Name:', labeler: :explicit, wrapper: :div
        }).and_return(input)
        expect(presenter.forme_input(form, :name, {})).to eql(input)
      end
    end

    describe 'when field is :description' do
      it 'should create text field' do
        expect(Forme::Input).to receive(:new).with(form, :text, {
          key: :description, value: 'bar', label: 'Description:', labeler: :explicit, wrapper: :div
        }).and_return(input)
        expect(presenter.forme_input(form, :description, {})).to eql(input)
      end
    end
  end
end

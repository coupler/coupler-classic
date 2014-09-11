require 'spec_helper'

describe ImportPresenter do
  let(:import) { double('import', path: '', filetype: 'csv') }
  subject(:presenter) { ImportPresenter.new(import) }

  describe '#forme_input' do
    let(:form) { double('form') }
    let(:input) { double('input') }

    describe 'when field is :path' do
      it 'should create file field' do
        expect(Forme::Input).to receive(:new).with(form, :file, {
          key: :path, label: 'File:', labeler: :explicit, wrapper: :div
        }).and_return(input)
        expect(presenter.forme_input(form, :path, {})).to eql(input)
      end
    end
  end
end

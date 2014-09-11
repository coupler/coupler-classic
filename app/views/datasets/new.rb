module Coupler
  module Datasets
    class New
      include Coupler::View

      def project
        @project ||= ProjectPresenter.new(locals[:project])
      end

      def import
        @import ||= ImportPresenter.new(locals[:import])
      end

      def import_form
        @import_form ||= Forme::Form.new(import)
      end
    end
  end
end

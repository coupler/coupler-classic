module Coupler
  module Projects
    class New
      include Coupler::View

      def project
        @project ||= ProjectPresenter.new(locals[:project])
      end

      def form
        @form ||= Forme::Form.new(project)
      end
    end
  end
end

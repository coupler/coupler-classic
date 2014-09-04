module Coupler
  module Projects
    class Show
      include Coupler::View

      def project
        @project ||= ProjectPresenter.new(locals[:project])
      end
    end
  end
end

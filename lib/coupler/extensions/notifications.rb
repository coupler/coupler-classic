module Coupler
  module Extensions
    module Notifications
      include Models

      def self.registered(app)
        app.get "/notifications" do
          @notifications = Notification.order(:created_at).all
          erb :"notifications/index"
        end
      end
    end
  end
end

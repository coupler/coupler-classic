module Coupler
  module Extensions
    module Notifications
      include Models

      def self.registered(app)
        app.before do
          Notification.filter(~{:seen => true}, {:url => request.path_info}).update(:seen => true)
        end

        app.get "/notifications" do
          @notifications = Notification.order(:created_at).all
          erb :"notifications/index"
        end

        app.get "/notifications/unseen.json" do
          content_type 'application/json'
          notifications = Notification.filter(~{:seen => true}).order(:created_at).all
          notifications.collect do |n|
            { 'id' => n.id, 'message' => n.message, 'url' => n.url, 'created_at' => n.created_at.iso8601 }
          end.to_json
        end
      end
    end
  end
end

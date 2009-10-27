module Coupler
  module Helpers
    def error_messages_for(object)
      return ""   if object.errors.empty?

      retval = "<div class='errors'><ul>"
      object.errors.each do |(attr, messages)|
        messages.each do |message|
          retval += "<li>"
          retval += attr.to_s.tr("_", " ").capitalize + " " if attr != :base
          retval += "#{message}</li>"
        end
      end
      retval += "</ul></div>"

      retval
    end
  end
end

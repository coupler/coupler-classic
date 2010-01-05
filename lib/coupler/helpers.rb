module Coupler
  module Helpers
    def error_messages_for(object)
      return ""   if object.errors.empty?

      retval = "<div class='errors'><h3>Errors detected:</h3><ul>"
      object.errors.each do |(attr, messages)|
        messages.each do |message|
          retval += "<li>"
          retval += attr.to_s.tr("_", " ").capitalize + " " if attr != :base
          retval += "#{message}</li>"
        end
      end
      retval += "</ul></div><div class='clear'></div>"

      retval
    end

    def javascripts
      @javascripts ||= %w{jquery.min.js}
    end

    def javascript_includes
      javascripts.collect do |name|
        %{<script type="text/javascript" src="/js/#{name}"></script>}
      end.join("\n  ")
    end

    def add_javascript(*names)
      javascripts.push(*names)
    end

    def stylesheets
      @stylesheets ||= %w{reset.css text.css 960.css style.css}
    end

    def stylesheet_links
      stylesheets.collect do |name|
        %{<link rel="stylesheet" type="text/css" media="all" href="/css/#{name}" />}
      end.join("\n  ")
    end

    def add_stylesheet(*names)
      stylesheets.push(*names)
    end

    def delete_link(text, url)
      %^<a href="#{url}" onclick="if (confirm('Are you sure?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href; var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m); f.submit(); }; return false;">#{text}</a>^
    end
  end
end

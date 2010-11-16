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
      @javascripts ||= %w{jquery.min.js jquery.timeago.js jquery-ui.min.js application.js}
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
      @stylesheets ||= %w{reset.css text.css 960.css jquery-ui.css jquery.treeview.css style.css}
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

    def breadcrumbs
      # This method is fun but silly.
      if @breadcrumbs
        url = ""
        %{<div id="breadcrumbs">} +
          @breadcrumbs.inject([]) do |arr, obj|
            strings =
              case obj
              when String
                [obj]
              when nil
                []
              else
                class_name = obj.class.to_s.split("::")[-1]
                if obj.new?
                  ["New #{class_name}"]
                elsif
                  url += "/#{class_name.downcase}s/#{obj.id}"
                  if obj.respond_to?(:name)
                    ["#{class_name}s", %{<a href="#{url}">#{obj.name}</a>}]
                  else
                    [%{<a href="#{url}">#{class_name} ##{obj.id}</a>}]
                  end
                end
              end
            arr.push(*strings.collect { |x| %{<div class="crumb">#{x}</div>} })
          end.join(%{<div class="crumb">/</div>}) +
          %{</div><div class="clear"></div>}
      end
    end

    def humanize(string)
      string.to_s.gsub(/_+/, " ").capitalize
    end

    def timeago(time, klass = nil, tag = "div")
      if time.nil?
        "Never"
      else
        dt = time.send(:to_datetime)
        klass = "timeago" + (klass.nil? ? "" : " #{klass}")
        %{<#{tag} class="#{klass}" title="#{dt.to_s}">#{time.to_s}</#{tag}>}
      end
    end

    def form_tag_for(obj, options)
      base_url = options[:base_url]
      action, method = if obj.new?
                         [base_url, ""]
                       else
                         ["#{base_url}/#{obj.id}", %{<div style="display: none;"><input type="hidden" name="_method" value="put" /></div>}]
                       end
      %{<form action="#{action}" method="post">#{method}}
    end

    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end

    def cycle(even, odd)
      (@_cycle = !@_cycle) ? even : odd
    end
  end
end

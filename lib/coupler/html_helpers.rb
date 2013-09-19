module Coupler
  module HtmlHelpers
    def open_tag(name, attribs = {})
      if attribs.empty?
        "<#{name}>"
      else
        attribs = attribs.collect do |key, value|
          value = value.gsub(/["\r\n\t]/) do |m|
            case m
            when '"' then "&quot;"
            else
              "&##{m.ord}"
            end
          end
          %{#{key}="#{value}"}
        end
        "<#{name} " + attribs.join(" ") + ">"
      end
    end

    def select_tag(name, options, selected = nil, html_options = {})
      result = open_tag('select', {'name' => name}.merge(html_options))
      options.each do |option|
        attribs = {}
        if option.is_a?(Array)
          attribs['value'], label = option
          active = selected == attribs['value']
        else
          label = option
          active = selected == label
        end
        if active
          attribs['selected'] = "selected"
        end
        result.concat(open_tag('option', attribs) + label + '</option>')
      end
      result.concat('</select>')
    end

    def csv_table(csv, limit = 25)
      begin
        result = "<table><thead><tr>"
        csv.shift.each do |name|
          result.concat('<th>' + name + '</th>')
        end
        result.concat('</tr></thead><tbody>')
        csv.to_enum(:each).with_index do |row, i|
          result.concat('<tr>')
          row.each do |value|
            result.concat('<td>' + value + '</td>')
          end
          result.concat('</tr>')
          break if i == limit
        end
        result.concat('</tbody></table>')
      rescue CSV::MalformedCSVError => e
        '<div class="error">' + e.message + '</div>'
      end
    end
  end
end

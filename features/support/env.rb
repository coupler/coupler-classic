require File.dirname(__FILE__) + "/../../test/helper"
require 'test/unit/assertions'
require 'celerity'

module CouplerWorld
  include Test::Unit::Assertions

  def app
    Coupler::Base.set :environment, :test
    Coupler::Base
  end

  def browser
    unless @browser
      @browser = Celerity::Browser.new({
        :javascript_exceptions => true, :viewer => "127.0.0.1:6429",
        :resynchronize => true, :css => true
      })
    end
    @browser
  end

  def visit(url)
    browser.goto(url)
  end

  def current_url
    browser.page.web_response.request_url.to_string
  end

  def current_page_source
    return nil    unless browser.page

    string_writer = java.io.StringWriter.new
    print_writer  = java.io.PrintWriter.new(string_writer)

    root = browser.page.document_element
    node_to_xml(root, print_writer)
    print_writer.close
    string_writer.to_string
  end

  # Fill in a text field with a value
  def fill_in(label_or_name, options = {})
    elt = find_element_by_label_or_name(:text_field, label_or_name)
    if elt.exist?
      elt.value = options[:with]
    end
  end

  def select(option_text, options = {})
    elt = find_element_by_label_or_name(:select_list, options[:from])
    if elt.exist?
      begin
        elt.select(option_text)
      rescue Celerity::Exception::CelerityException
        elt.select_value(option_text)
      end
    end
  end

  def click_button(button_value)
    browser.button(button_value).click
  end

  def find_visible_element_by_label_or_id(label_or_id, which = 0)
    labels = browser.labels.select do |label|
      object = label.object
      object.textContent == label_or_id && object.displayed?
    end
    id = labels.empty? ? label_or_id : labels[which].for
    browser.elements_by_xpath("id('#{id}')")[0]
  end

  private
    # NOTE: I have to do this because HtmlUnit's asXml likes to put spaces
    #       and newlines in the middle of whitespace-sensitive tags (like
    #       <a> and <textarea>).  Fail.
    def node_to_xml(node, print_writer)
      closing_tag = false

      case node
      when HtmlUnit::Html::DomText
        # just print out the text
        print_writer.write(HtmlUnit::Util::StringUtils.escape_xml_chars(node.data))
      when HtmlUnit::Html::DomCDataSection, HtmlUnit::Html::DomProcessingInstruction
        # use default printXml here
        node.print_xml("", print_writer)
      when HtmlUnit::Html::DomComment
        print_writer.write("<!-- #{node.data} -->")
      when HtmlUnit::Html::HtmlTextArea
        node_print_opening_tag(node, print_writer)
        print_writer.write(node.text)
        closing_tag = true
      else
        node_print_opening_tag(node, print_writer)
        closing_tag = true
      end

      child = node.first_child
      while child
        node_to_xml(child, print_writer)
        child = child.next_sibling
      end

      node_print_closing_tag(node, print_writer) if closing_tag
    end

    def node_print_opening_tag(node, print_writer)
      print_writer.write("<")
      node.print_opening_tag_content_as_xml(print_writer)
      print_writer.write(">")
    end

    def node_print_closing_tag(node, print_writer)
      print_writer.write("</#{node.tag_name}>")
    end
end

Before do
  database = Coupler::Database.instance
  database.tables.each do |name|
    next  if name == :schema_info
    database[name].delete
  end
end

World(CouplerWorld)

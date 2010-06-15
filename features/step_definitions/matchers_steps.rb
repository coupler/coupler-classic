When /^I select "([^\"]*)" as the (first|second) type$/ do |type, which|
  name = case which
         when "first" then "lhs"
         when "second" then "rhs"
         else raise "bad which"
         end
  browser.select_list(:id => "#{name}_type").select(type)
end

When /^I select "([^\"]*)" for "([^\"]*)" as the (first|second) value$/ do |field, resource, which|
  name = case which
         when "first" then "lhs"
         when "second" then "rhs"
         else raise "bad which"
         end
  s = browser.select_list(:id => "#{name}_value_select")
  optgroup = s.object.child_nodes.detect do |node|
    Java::ComGargoylesoftwareHtmlunitHtml::HtmlOptionGroup === node &&
      node.label_attribute == resource
  end
  option = optgroup.child_nodes.detect do |node|
    Java::ComGargoylesoftwareHtmlunitHtml::HtmlOption === node &&
      node.text == field
  end
  s.object.set_selected_attribute(option, true)
end

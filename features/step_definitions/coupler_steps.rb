Given /^that I have created a project called "(.+?)"$/ do |project_name|
  @project_name = project_name
  @project = Factory(:project, :name => project_name)
end

Given /^that I have added a resource called "(.+?)"$/ do |resource_name|
  @resource_name = resource_name
  @resource = Factory(:resource, :name => resource_name, :project => @project)
end

Given /^that I have added a "([^\"]*)" transformation for "([^\"]*)"$/ do |transformer, field|
  @transformation = Factory(:transformation, {
    :resource => @resource, :transformer_name => transformer,
    :field_name => field
  })
end

When /^I go to the (.+?) page$/ do |page_name|
  @page_name = page_name
  path = case page_name
         when "front"
           "/"
         when "project"
           "/projects/#{@project.slug}"
         when "resource"
           "/projects/#{@project.slug}/resources/#{@resource.id}"
         end
  visit("http://localhost:4567#{path}")
end

When /^I click the "(.+?)" link$/ do |link_name|
  link = browser.link(:text, link_name)
  assert link.exist?, "can't find the '#{link_name}' link"
  link.click
end

When /^I fill in the form:$/ do |table|
  table.raw.each do |(label_or_name, value)|
    elt = nil
    [:text_field, :select_list].each do |type|
      elt = find_element_by_label_or_name(type, label_or_name)
      break if elt.exist?
    end
    assert elt.exist?, "can't find element with label or name of '#{label_or_name}'"

    case elt
    when Celerity::TextField
      elt.value = value
    when Celerity::SelectList
      elt.select(value)
    end
  end
end

When /^I click the "(.+?)" button$/ do |button_name|
  click_button(button_name)
end

Then /^it should show me a confirmation page$/ do
  assert_match /successfully created/, current_page_source
end

Then /^ask me to (.+)$/ do |question|
  assert current_page_source.include?(question)
end

Then /^it should take me back to the (\w+) page$/ do |page_name|
  case page_name
  when 'resource'
    assert_match %r{/projects/#{@project.slug}/resources/#{@resource.id}$}, current_url
  end
end

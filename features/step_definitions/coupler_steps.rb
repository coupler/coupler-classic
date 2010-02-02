Given /^that I have created a project called "(.+?)"$/ do |project_name|
  @project_name = project_name
  @project = Factory(:project, :name => project_name)
end

Given /^that I have added the "(.+?)" resource$/ do |resource_name|
  @resource_name = resource_name
  options = case resource_name
            when "People"
              { :table_name => "people" }
            when "Pets"
              { :table_name => "pets" }
            end
  @resources ||= []
  @resources << Factory(:resource, {:name => resource_name, :project => @project}.merge(options))
end

Given /^that I have added a "([^\"]*)" transformation for "([^\"]*)"$/ do |transformer, field|
  @transformation = Factory(:transformation, {
    :resource => @resources.last, :transformer_name => transformer,
    :field_name => field
  })
end

Given /^that I have created a scenario called "([^"]*)"$/ do |scenario_name|
  @scenario = Factory(:scenario, {
    :name => scenario_name, :type => "self-join",
    :project => @project
  })
  @scenario.add_resource(@resources.last)
end

Given /^that I have created a dual-join scenario called "([^"]*)"$/ do |scenario_name|
  @scenario = Factory(:scenario, {
    :name => scenario_name, :type => "dual-join",
    :project => @project
  })
  @scenario.add_resource(@resources[0])
  @scenario.add_resource(@resources[1])
end

Given /^that I have added a "([^\"]*)" matcher with these options:$/ do |comparator_name, table|
  comparator_options = {}
  table.raw.each do |(key, value)|
    comparator_options[key] = value
  end
  @matcher = Factory(:matcher, {
    :comparator_name => comparator_name,
    :comparator_options => comparator_options,
    :scenario => @scenario
  })
end

When /^I go to the (.+?) page$/ do |page_name|
  @page_name = page_name
  path = case page_name
         when "front"
           "/"
         when "project"
           "/projects/#{@project.id}"
         when "resource"
           "/projects/#{@project.id}/resources/#{@resources.last.id}"
         when "scenario"
           "/projects/#{@project.id}/scenarios/#{@scenario.id}"
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
      value.split("/").each { |v| elt.select(v) }
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
    assert_match %r{/projects/#{@project.id}/resources/#{@resources.last.id}$}, current_url
  end
end

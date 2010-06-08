Given /^that I have created a connection called "(.+?)"$/ do |connection_name|
  @connection_name = connection_name
  @connection = Factory(:connection, :name => connection_name)
end

Given /^that I have created a project called "(.+?)"$/ do |project_name|
  @project_name = project_name
  @project = Factory(:project, :name => project_name)
end

Given /^that I have created a transformer called "(.+?)"$/ do |transformer_name|
  @transformer_name = transformer_name
  @transformer = Factory(:transformer, :name => transformer_name)
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
  @resources << Factory(:resource, {:name => resource_name, :project => @project, :connection => @connection}.merge(options))
end

Given /^that I have added a transformation for "([^\"]*)"$/ do |field|
  resource = @resources[0]
  @transformation = Factory(:transformation, {
    :resource => resource, :transformer => @transformer,
    :field => resource.fields_dataset[:name => field]
  })
end

Given /^that I have created a self-linkage scenario called "([^"]*)"$/ do |scenario_name|
  @scenario = Factory(:scenario, {
    :name => scenario_name, :resource_1_id => @resources[0].id,
    :project => @project
  })
end

Given /^that I have created a dual-linkage scenario called "([^"]*)"$/ do |scenario_name|
  @scenario = Factory(:scenario, {
    :name => scenario_name, :project => @project,
    :resource_1_id => @resources[0].id, :resource_2_id => @resources[1].id
  })
end

Given /^that I have added a matcher with these options:$/ do |table|
  comparisons_attributes = []
  resources = @scenario.resources
  table.hashes.each do |hash|
    lhs_value = hash["Type 1"] == "field" ? resources[0].fields_dataset[:name => hash["Value 1"]].id : hash["Value 1"]
    rhs_value = hash["Type 2"] == "field" ? resources[-1].fields_dataset[:name => hash["Value 2"]].id : hash["Value 2"]
    comparisons_attributes << {
      "lhs_type" => hash["Type 1"], "lhs_value" => lhs_value,
      "rhs_type" => hash["Type 2"], "rhs_value" => rhs_value,
      "operator" => hash["Operator"]
    }
  end
  @matcher = Factory(:matcher, {
    :comparisons_attributes => comparisons_attributes,
    :scenario => @scenario
  })
end

When /^I go to the (.+?) page$/ do |page_name|
  @page_name = page_name
  path = case page_name
         when "front"
           "/"
         when "connections"
           "/connections"
         when "projects"
           "/projects"
         when "project"
           "/projects/#{@project.id}"
         when "resource"
           "/projects/#{@project.id}/resources/#{@resources[0].id}"
         when "transformations"
           "/projects/#{@project.id}/resources/#{@resources[0].id}/transformations"
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

When /^I click the "(.+?)" button with confirmation$/ do |button_name|
  browser.confirm(true) do
    click_button(button_name)
  end
end

Then /^(?:it should )?show me a confirmation notice$/ do
  assert_match /successfully created|created successfully/, current_page_source
end

Then /^ask me to (.+)$/ do |question|
  question = question.sub(/\bI\b/, "you")
  assert current_page_source.include?(question)
end

Then /^it should take me back to the (\w+) page$/ do |page_name|
  case page_name
  when 'resource'
    assert_match %r{/projects/#{@project.id}/resources/#{@resources[0].id}$}, current_url
  end
end

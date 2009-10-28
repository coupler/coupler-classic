Given /^that I have created a project called "(.+?)"$/ do |project_name|
  @project_name = project_name
  @project = Factory(:project, :name => project_name)
end

Given /^that I have added a resource called "(.+?)"$/ do |resource_name|
  @resource_name = resource_name
  @resource = Factory(:resource, :name => resource_name, :project => @project)
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
  visit(path)
end

When /^I click the "(.+?)" link$/ do |link_name|
  browser.link(:text, link_name).click
end

When /^I fill in the form$/ do
  begin
    case current_url
    when %r{/projects/new$}
      @type = 'project'
      fill_in 'Name', :with => 'foo'

    when %r{/projects/.+?/resources/new$}
      @type = 'resource'
      fill_in 'Name', :with => 'people'
      fill_in 'Host', :with => 'localhost'
      fill_in 'Port', :with => '12345'
      fill_in 'Username', :with => 'coupler'
      fill_in 'Password', :with => 'cupla'
      fill_in 'Database', :with => 'fake_data'
      fill_in 'Table', :with => 'people'
    end
  rescue
    puts current_page_source
    raise
  end
end

When /^I select "([^"]*)" for "([^"]*)"$/ do |option, select|
  select option, :from => select
end

When /^I click the "(.+?)" button$/ do |button_name|
  click_button(button_name)
end

Then /^it should show me a confirmation page$/ do
  assert_match /#{@type.capitalize} successfully created/, current_page_source
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

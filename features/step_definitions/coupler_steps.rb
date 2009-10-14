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
  url = case page_name
        when "front"
          "/"
        when "project"
          "/projects/#{@project.slug}"
        when "resource"
          "/project/#{@project.slug}/resources/#{@resource.id}"
        end
  @response = visit(url)
end

When /^I click the "(.+?)" link$/ do |link_name|
  @response = click_link(link_name)
end

When /^I fill in the form$/ do
  case current_url
  when "/projects/new"
    @type = 'project'

    fill_in 'Name', :with => 'foo'
  when %r{^/projects/.+?/resources/new$}
    @type = 'resource'

    fill_in 'Name', :with => 'people'
    fill_in 'Host', :with => 'localhost'
    fill_in 'Username', :with => 'coupler'
    fill_in 'Password', :with => 'cupla'
    fill_in 'Database', :with => 'coupler_test'
    fill_in 'Table', :with => 'people'
  end
end

When /^I click the "(.+?)" button$/ do |button_name|
  @response = click_button(button_name)
end

Then /^it should show me a confirmation page$/ do
  assert_match /#{@type.capitalize} successfully created/, @response.body
end

Then /^ask me to (.+)$/ do |question|
  assert @response.body.include?(question)
end

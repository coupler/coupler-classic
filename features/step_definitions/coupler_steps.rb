Given /^that I have created a project called "(.+?)"$/ do |project_name|
  @project_name = project_name
  @project = Coupler::Project.create(:name => project_name)
end

When /^I go to the (.+?) page$/ do |page_name|
  @page_name = page_name
  url = case page_name
        when "front" then "/"
        when "project" then "/projects/#{@project.slug}"
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

    fill_in 'Name', :with => 'roflsauce'
  when %r{^/projects/.+?/resources/new$}
    @type = 'resource'

    fill_in 'Name', :with => 'roflpwn'
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

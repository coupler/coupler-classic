Given /^that I am viewing "(.+?)"$/ do |url|
  visit url
end

When /^I click "(.+?)"$/ do |text|
  click_link text
end

When /^I create a new database called "(\w+)"$/ do |name|
  @name = name

  fill_in "Name", :with => name
  select 'MySQL', :from => "Adapter"
  fill_in "Host", :with => "localhost"
  fill_in "Port", :with => "3306"
  fill_in "Username", :with => "coupler"
  fill_in "Password", :with => "omgponies"
  fill_in "Database", :with => "foo"
  click_button "Submit"
end

Then /^that database should exist$/ do
  assert Coupler::Database[:name => @name]
end

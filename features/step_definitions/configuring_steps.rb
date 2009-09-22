Given /^that I am viewing "(.+?)"$/ do |url|
  visit url
end

Given /^that I have created a database called "(.+?)"$/ do |dbname|
  @dbname = dbname

  Coupler::Database.create({
    'adapter' => 'mysql', 'host' => 'localhost', 'port' => '3306',
    'username' => 'coupler', 'password' => 'omgponies',
    'dbname' => dbname
  })
end

When /^I click "(.+?)"$/ do |text|
  click_link text
end

When /^I create a new database called "(\w+)"$/ do |dbname|
  @dbname = dbname

  fill_in "Name", :with => dbname
  select 'MySQL', :from => "Adapter"
  fill_in "Host", :with => "localhost"
  fill_in "Port", :with => "3306"
  fill_in "Username", :with => "coupler"
  fill_in "Password", :with => "omgponies"
  fill_in "Database", :with => "foo"
  click_button "Submit"
end

When /^I create a new resource on database "(\w+)" and table "(\w+)"$/ do |dbname, table_name|
  @dbname = dbname
  @table_name = table_name

  select dbname, :from => "Database"
  fill_in "Table", :with => table_name
  click_button "Submit"
end

Then /^that database should exist$/ do
  assert Coupler::Database[:name => @dbname]
end

Then /^that resource should exist$/ do
  assert Coupler::Resource[:table_name => @table_name]
end

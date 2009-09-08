Given /^that I am viewing "(.+?)"$/ do |url|
  visit(url)
end

When /^I add a "(\w+)" resource$/ do |type|
  select "MySQL", :from => "Adapter"
  fill_in "Host", :with => "localhost"
  fill_in "Port", :with => "3306"
  fill_in "Username", :with => "root"
  fill_in "Password", :with => "omgponies"
  fill_in "Database", :with => "hogwarts"
  fill_in "Table", :with => "students"
  click_button "Submit"
end

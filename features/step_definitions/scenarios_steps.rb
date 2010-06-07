When /^I click the "([^"]+)" resource/ do |resource_name|
  browser.li(:text, resource_name).click
end

Then /^it should start the linkage process$/ do
  assert_match /running/, current_page_source
end

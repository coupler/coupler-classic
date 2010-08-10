When /I click on the (\w+) icon next to the "([^"]+)" field/ do |icon, field|
  image = browser.cell(:text => field).parent.image(:src => /#{icon}/)
  image.parent.click
end

When /I choose a "([^"]+)" resource/ do |name|
  browser.execute_script(%{$('#resource-#{name.downcase}').show();})
end

Then /^it should start transforming$/ do
  assert_match /running/, current_page_source
end

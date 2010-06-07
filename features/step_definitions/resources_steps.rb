When /I click on the (\w+) icon next to the "([^"]+)" field/ do |icon, field|
  image = browser.cell(:text => field).parent.image(:src => /#{icon}/)
  image.parent.click
end

Then /^it should start transforming$/ do
  assert_match /running/, current_page_source
end

Then /^there should be no more transformations$/ do
  assert_equal 0, @resources.last.transformations_dataset.count
end

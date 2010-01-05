Then /^there should be no more transformations$/ do
  assert_equal 0, @resource.transformations_dataset.count
end

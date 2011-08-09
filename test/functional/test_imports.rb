require 'helper'

module CouplerFunctionalTests
  class TestImports < Coupler::Test::FunctionalTest
    def setup
      super
      @project = Project.create(:name => 'foo')
    end

    attribute(:javascript, true)
    test "upload" do
      visit "/projects/#{@project.id}/resources/new"
      find('label[for="resource-type-csv"]').click
      attach_file('data', fixture_path('people.csv'))

      assert_equal "/projects/#{@project.id}/imports/upload", page.current_path
      assert page.has_selector?('input#name')
    end

    attribute(:javascript, true)
    test "upload with no headers" do
      visit "/projects/#{@project.id}/resources/new"
      find('label[for="resource-type-csv"]').click
      attach_file('data', fixture_path('no-headers.csv'))

      assert_equal "/projects/#{@project.id}/imports/upload", page.current_path
      assert page.has_selector?('input#name')
    end

    attribute(:javascript, true)
    test "create with no issues" do
      visit "/projects/#{@project.id}/resources/new"
      find('label[for="resource-type-csv"]').click
      attach_file('data', fixture_path('people.csv'))

      job_count = Job.count
      click_button('Begin Importing')
      assert_match %r{^/projects/#{@project[:id]}/resources$}, page.current_path
      assert_equal job_count + 1, Job.count
    end

    attribute(:javascript, true)
    test "create with invalid import, fix, and continue" do
      visit "/projects/#{@project.id}/resources/new"
      find('label[for="resource-type-csv"]').click
      attach_file('data', fixture_path('people.csv'))

      fill_in('name', :with => '')
      click_button('Begin Importing')

      assert page.has_selector?("div.errors")

      fill_in('name', :with => 'Foo Bar')
      click_button('Begin Importing')
      assert_match %r{^/projects/#{@project[:id]}/resources$}, page.current_path
    end

    attribute(:javascript, true)
    test "editing import with duplicate keys" do
      import = Import.create(:data => fixture_file_upload("duplicate-keys.csv"), :project => @project)
      import.import!

      visit "/projects/#{@project.id}/imports/#{import.id}/edit"
      assert find("h2").has_content?("Duplicate Keys")
    end

    attribute(:javascript, true)
    test "update import with duplicate keys" do
      import = Import.create(:data => fixture_file_upload("duplicate-keys.csv"), :project => @project)
      import.import!

      visit "/projects/#{@project.id}/imports/#{import.id}/edit"
      find('input[name="delete[2][]"][value="1"]').click
      click_button('Submit')

      assert_match %r{^/projects/#{@project[:id]}/resources/\d+$}, page.current_path
    end
  end
end

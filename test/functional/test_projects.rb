require 'helper'

module CouplerFunctionalTests
  class TestProjects < Coupler::Test::FunctionalTest
    test "projects" do
      visit "/projects"
      assert_equal 200, page.status_code
    end

    test "create project" do
      visit "/projects/new"
      assert_equal 200, page.status_code

      within('form[action="/projects"]') do
        fill_in("Name", :with => "foo")
        fill_in("Description", :with => "foo bar")
        click_button("Submit")
      end

      assert_match %r{/projects/\d+}, page.current_path
      assert page.has_content?("Project successfully created")
    end

    test "showing invalid project when projects exist" do
      visit "/projects/8675309"
      assert_not_equal "/projects/8675309", page.current_path
      assert page.has_content?("The project you were looking for doesn't exist")
    end

    test "edit project" do
      project = Project.create(:name => 'foo')
      visit "/projects/#{project.id}/edit"

      within("form[action='/projects/#{project.id}']") do
        fill_in("Name", :with => "bar")
        fill_in("Description", :with => "bar foo")
        click_button("Submit")
      end

      assert_match %r{/projects/\d+}, page.current_path
    end

    attribute(:javascript, true)
    test "delete" do
      project = Project.create(:name => 'foo')
      visit "/projects"
      find('button.delete-project').click
      find('#yes-button').click
      assert_equal "/projects", page.current_path
      #assert_nil Project[:id => project.id]
    end

    attribute(:javascript, true)
    test "delete with versions" do
      project = Project.create(:name => 'foo')
      visit "/projects"
      find('button.delete-project').click
      find('#nuke').click
      yes = find('#yes-button')
      yes.click
      yes.click
      assert_equal "/projects", page.current_path
      assert_nil Project[:id => project.id]
      assert_nil Database.instance[:projects_versions][:current_id => project.id]
    end
  end
end

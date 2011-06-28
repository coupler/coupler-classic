require 'helper'

module CouplerFunctionalTests
  class TestBase < Coupler::Test::FunctionalTest
    def test_index_when_no_projects
      visit("/")
      assert_equal 200, page.status_code
      assert page.has_content?('Getting Started')
    end

    def test_redirect_when_projects_exist
      project = Project.create(:name => 'foo')
      visit("/")
      assert_equal "/projects", current_path
    end
  end
end

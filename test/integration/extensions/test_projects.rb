require 'helper'

module TestExtensions
  class TestProjects < Coupler::Test::IntegrationTest
    test "projects" do
      get "/projects"
      assert last_response.ok?
    end

    test "new project" do
      get "/projects/new"
      assert last_response.ok?

      doc = Nokogiri::HTML(last_response.body)
      assert_equal 1, doc.css('form[action="/projects"]').length
      %w{name description}.each do |name|
        assert_equal 1, doc.css("input[name='project[#{name}]']").length
      end
    end

    test "create project" do
      post "/projects", {
        'project' => {
          'name' => 'foo', 'description' => 'foo bar',
        }
      }
      assert_equal 1, Project.count
      assert last_response.redirect?, "Wasn't redirected"
      follow_redirect!

      project = Project.first
      assert_equal "http://example.org/projects/#{project.id}", last_request.url
      assert_match /Project successfully created/, last_response.body
    end

    test "show project" do
      project = Project.create(:name => 'foo')
      get "/projects/#{project.id}"
      assert last_response.ok?
      assert_match /foo/, last_response.body
    end

    test "showing invalid project when projects exist" do
      project = Project.create(:name => 'foo')
      get "/projects/8675309"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "edit project" do
      project = Project.create(:name => 'foo')
      get "/projects/#{project.id}/edit"
      assert last_response.ok?
    end

    test "update project" do
      project = Project.create(:name => 'foo')
      put "/projects/#{project.id}", :project => {:name => "Hee haw"}
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
    end

    test "delete" do
      project = Project.create(:name => 'foo')
      delete "/projects/#{project.id}"
      assert_nil Project[:id => project.id]
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
    end

    test "delete with versions" do
      project = Project.create(:name => 'foo')
      delete "/projects/#{project.id}", :nuke => "true"
      assert_nil Project[:id => project.id]
      assert_nil Database.instance[:projects_versions][:current_id => project.id]
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
    end
  end
end

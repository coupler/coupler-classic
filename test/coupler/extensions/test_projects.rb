require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestProjects < Test::Unit::TestCase
      def test_projects
        get "/projects"
        assert last_response.ok?
      end

      def test_new_project
        get "/projects/new"
        assert last_response.ok?

        doc = Nokogiri::HTML(last_response.body)
        assert_equal 1, doc.css('form[action="/projects"]').length
        %w{name description}.each do |name|
          assert_equal 1, doc.css("input[name='project[#{name}]']").length
        end
      end

      def test_create_project
        post "/projects", {
          'project' => {
            'name' => 'omgponies', 'description' => 'Ponies',
          }
        }
        assert_equal 1, Models::Project.count
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!

        project = Models::Project.first
        assert_equal "http://example.org/projects/#{project.id}", last_request.url
        assert_match /Project successfully created/, last_response.body
      end

      def test_show_project
        project = Factory(:project, :name => "Blah blah")
        get "/projects/#{project.id}"
        assert last_response.ok?
        assert_match /Blah blah/, last_response.body
      end

      def test_edit_project
        project = Factory(:project, :name => "Blah blah")
        get "/projects/#{project.id}/edit"
        assert last_response.ok?
      end

      def test_update_project
        project = Factory(:project, :name => "Blah blah")
        put "/projects/#{project.id}", :project => {:name => "Hee haw"}
        assert last_response.redirect?
        assert_equal "/projects", last_response['location']
      end

      def test_delete
        project = Factory(:project, :name => "Blah blah")
        delete "/projects/#{project.id}"
        assert_nil Models::Project[:id => project.id]
        assert last_response.redirect?
        assert_equal "/projects", last_response['location']
      end

      def test_delete_with_versions
        project = Factory(:project, :name => "Blah blah")
        delete "/projects/#{project.id}", :nuke => "true"
        assert_nil Models::Project[:id => project.id]
        assert_nil Database.instance[:projects_versions][:current_id => project.id]
        assert last_response.redirect?
        assert_equal "/projects", last_response['location']
      end
    end
  end
end

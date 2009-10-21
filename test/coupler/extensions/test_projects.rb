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
        Models::Project.delete
        assert_equal 0, Models::Project.count
        post "/projects", {
          'project' => {
            'name' => 'omgponies', 'description' => 'Ponies',
          }
        }
        assert_equal 1, Models::Project.count
        assert last_response.redirect?, "Wasn't redirected"
        follow_redirect!
        assert_equal "http://example.org/projects/omgponies", last_request.url
        assert_match /Project successfully created/, last_response.body
      end

      def test_show_project
        project = Factory(:project, :name => "Blah blah")
        get "/projects/#{project.slug}"
        assert last_response.ok?
        assert_match /Blah blah/, last_response.body
      end
    end
  end
end

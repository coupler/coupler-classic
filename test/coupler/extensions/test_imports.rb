require File.dirname(__FILE__) + '/../../helper'

module Coupler
  module Extensions
    class TestImports < Test::Unit::TestCase
      def setup
        super
        @project = Factory(:project)
      end

      def test_create
        import = mock('import', :id => 123, :valid? => true, :save => nil)
        Models::Import.expects(:new).with do |hash|
          hash[:data].kind_of?(Hash) && hash[:project].id == @project.id
        end.returns(import)

        post "/projects/#{@project.id}/imports", :import => { :data => fixture_file_upload("people.csv") }
        assert last_response.redirect?
        assert_equal "/projects/#{@project[:id]}/imports/123/edit", last_response['location']
      end

      def test_edit
        import = Models::Import.create(:data => fixture_file_upload("people.csv"), :project => @project)
        get "/projects/#{@project.id}/imports/#{import.id}/edit"
        assert last_response.ok?
      end

      def test_update
        params = { 'import' => { 'fields' => { 'age' => { 'type' => 'string' } } } }
        import = mock("import", :save => true)
        import.expects(:set).with(params['import'])
        Models::Import.expects(:[]).with(:id => '123', :project_id => @project.id).returns(import)
        resource = mock("resource", :id => 456, :valid? => true, :save => true)
        Models::Resource.expects(:new).with(:import => import).returns(resource)

        put "/projects/#{@project[:id]}/imports/123", params
        assert last_response.redirect?
        assert_equal "/projects/#{@project.id}/resources/456", last_response['location']
      end

      def test_failed_update
        params = { 'import' => { 'field_types' => { 'age' => { 'type' => 'string' } } } }
        import = Factory(:import, :project => @project)
        resource = mock("resource", :valid? => false)
        resource.expects(:errors).at_least_once.returns({:foo => ["bar"]})
        Models::Resource.expects(:new).with do |hash|
          assert_equal import.id, hash[:import].id; true
        end.returns(resource)

        put "/projects/#{@project[:id]}/imports/#{import.id}", params
        assert last_response.ok?
      end
    end
  end
end

require 'helper'

module Coupler
  module Extensions
    class TestImports < Coupler::Test::UnitTest
      def setup
        super
        @project = Factory(:project)
      end

      def test_upload_saves_file
        post "/projects/#{@project.id}/imports/upload", :data => fixture_file_upload("people.csv")
        assert last_response.ok?
      end

      def test_upload_with_no_headers
        post "/projects/#{@project.id}/imports/upload", :data => fixture_file_upload("no-headers.csv")
        assert last_response.ok?
      end

      def test_create_with_no_issues
        cached_import = Factory.build(:import, :project => @project)
        new_import = mock(:save => true, :import! => true)
        Models::Import.expects(:new).returns(new_import)
        Models::Resource.expects(:new).with(:import => new_import).returns(mock({
          :valid? => true, :save => true, :id => 123
        }))

        post("/projects/#{@project.id}/imports", {
          :import => {
            :name => cached_import.name,
            :data_cache => cached_import.data_cache,
            :primary_key_name => cached_import.primary_key_name,
            :field_names => cached_import.field_names,
            :field_types => cached_import.field_types
          }
        })
        assert last_response.redirect?
        assert_equal "http://example.org/projects/#{@project[:id]}/resources/123", last_response['location']
      end

      def test_create_with_invalid_import
        import = Factory.build(:import, :project => @project)
        Models::Import.expects(:new).returns(import)
        import.expects(:save).returns(false)

        post("/projects/#{@project.id}/imports", {
          :import => {
            :name => import.name,
            :data_cache => import.data_cache,
            :primary_key_name => import.primary_key_name,
            :field_names => import.field_names,
            :field_types => import.field_types
          }
        })
        assert last_response.ok?
      end

      def test_create_with_non_existant_project
        post "/projects/8675309/imports"
        assert last_response.redirect?
        assert_equal "http://example.org/projects", last_response['location']
        follow_redirect!
        assert_match /The project you were looking for doesn't exist/, last_response.body
      end

      def test_create_with_failed_import
        import = Factory.build(:import, :data => fixture_file_upload('duplicate-keys.csv'), :project => @project)
        Models::Import.expects(:new).returns(import)
        import.expects(:import!).returns(false)

        post("/projects/#{@project.id}/imports", {
          :import => {
            :name => import.name,
            :data_cache => import.data_cache,
            :primary_key_name => import.primary_key_name,
            :field_names => import.field_names,
            :field_types => import.field_types
          }
        })
        assert last_response.redirect?, "Wasn't redirected"
        assert_equal "http://example.org/projects/#{@project.id}/imports/#{import.id}/edit", last_response['location']
      end

      def test_edit_import_with_duplicate_keys
        import = Factory.create(:import, :data => fixture_file_upload('duplicate-keys.csv'), :project => @project)
        import.import!
        get "/projects/#{@project.id}/imports/#{import.id}/edit"
        assert last_response.ok?
      end

      def test_update_import_with_duplicate_keys
        import = Factory(:import, :data => fixture_file_upload('duplicate-keys.csv'), :project => @project)
        import.import!
        Models::Import.expects(:[]).returns(import)
        import.expects(:repair_duplicate_keys!).with({"1"=>%w{1 2}})
        Models::Resource.expects(:create).with(:import => import).returns(mock(:id => 123))

        put("/projects/#{@project[:id]}/imports/#{import.id}", { :delete => { "1" => ["1", "2"] }})
        assert last_response.redirect?
        assert_equal "http://example.org/projects/#{@project[:id]}/resources/123", last_response['location']
      end

      #def test_edit
        #import = Models::Import.create(:data => fixture_file_upload("people.csv"), :project => @project)
        #get "/projects/#{@project.id}/imports/#{import.id}/edit"
        #assert last_response.ok?
      #end

      #def test_edit_with_non_existant_import
        #get "/projects/#{@project.id}/imports/8675309/edit"
        #assert last_response.redirect?
        #assert_equal "http://example.org/projects/#{@project.id}", last_response['location']
        #follow_redirect!
        #assert_match /The import you were looking for doesn't exist/, last_response.body
      #end

      #def test_update
        #params = { 'import' => { 'field_names' => %w{id first_name last_name age}, 'field_types' => %w{integer string string integer}, 'primary_key_name' => 'id' } }
        #import = mock("import", :save => true, :import! => true)
        #import.expects(:set).with(params['import'])
        #Models::Import.expects(:[]).with(:id => '123', :project_id => @project.id).returns(import)
        #resource = mock("resource", :id => 456, :valid? => true, :save => true)
        #Models::Resource.expects(:new).with(:import => import).returns(resource)

        #put "/projects/#{@project[:id]}/imports/123", params
        #assert last_response.redirect?
        #assert_equal "http://example.org/projects/#{@project.id}/resources/456", last_response['location']
      #end

      #def test_update_with_failed_resource_save
        #params = { 'import' => { 'field_names' => %w{id first_name last_name age}, 'field_types' => %w{integer string string integer}, 'primary_key_name' => 'id' } }
        #import = Factory(:import, :project => @project)
        #import.expects(:set).with(params['import'])
        #Models::Import.expects(:[]).with(:id => '123', :project_id => @project.id).returns(import)
        #resource = mock("resource", :valid? => false)
        #resource.expects(:errors).at_least_once.returns({:foo => ["bar"]})
        #Models::Resource.expects(:new).with do |hash|
          #import == hash[:import]
        #end.returns(resource)

        #put "/projects/#{@project[:id]}/imports/123", params
        #assert last_response.ok?
      #end

      #def test_update_with_no_field_names
        #params = { 'import' => { 'field_types' => %w{integer string string integer}, } }
        #import = Factory(:import, :name => 'foo', :data => fixture_file_upload('no-headers.csv'), :project => @project)

        #put "/projects/#{@project[:id]}/imports/#{import.id}", params
        #assert last_response.ok?
      #end

      #def test_update_with_duplicate_keys
        #params = { 'import' => { 'field_names' => %w{id foo bar}, 'field_types' => %w{integer string string}, 'primary_key_name' => 'id' } }
        #import = Factory(:import, :data => fixture_file_upload('duplicate-keys.csv'), :project => @project)
        #import.import!

        #put "/projects/#{@project[:id]}/imports/#{import.id}", params
        #assert last_response.ok?
      #end
    end
  end
end

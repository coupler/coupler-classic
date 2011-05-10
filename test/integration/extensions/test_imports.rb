require 'helper'

module TestExtensions
  class TestImports < Coupler::Test::IntegrationTest
    def setup
      super
      @project = Project.create(:name => 'foo')
    end

    test "upload saves file" do
      post "/projects/#{@project.id}/imports/upload", :data => fixture_file_upload("people.csv")
      assert last_response.ok?
    end

    test "upload with no headers" do
      post "/projects/#{@project.id}/imports/upload", :data => fixture_file_upload("no-headers.csv")
      assert last_response.ok?
    end

    test "create with no issues" do
      cached_import = Import.new(:project => @project, :data => fixture_file_upload('people.csv'))

      post("/projects/#{@project.id}/imports", {
        :import => {
          :name => cached_import.name,
          :data_cache => cached_import.data_cache,
          :primary_key_name => cached_import.primary_key_name,
          :field_names => cached_import.field_names,
          :field_types => cached_import.field_types
        }
      })
      assert last_response.redirect?, "Wasn't a redirect"
      assert_match %r{^http://example.org/projects/#{@project[:id]}/resources/\d+$}, last_response['location']
    end

    test "create with invalid import" do
      cached_import = Import.new(:project => @project, :data => fixture_file_upload('people.csv'))

      post("/projects/#{@project.id}/imports", {
        :import => {
          :name => cached_import.name,
          :data_cache => cached_import.data_cache,
          :primary_key_name => cached_import.primary_key_name,
          :field_names => nil,
          :field_types => cached_import.field_types
        }
      })
      assert last_response.ok?
    end

    test "create with non existant project" do
      post "/projects/8675309/imports"
      assert last_response.redirect?
      assert_equal "http://example.org/projects", last_response['location']
      follow_redirect!
      assert_match /The project you were looking for doesn't exist/, last_response.body
    end

    test "create with failed import" do
      cached_import = Import.new(:project => @project, :data => fixture_file_upload('duplicate-keys.csv'))

      post("/projects/#{@project.id}/imports", {
        :import => {
          :name => cached_import.name,
          :data_cache => cached_import.data_cache,
          :primary_key_name => cached_import.primary_key_name,
          :field_names => cached_import.field_names,
          :field_types => cached_import.field_types
        }
      })
      assert last_response.redirect?, "Wasn't redirected"
      assert_match %r{http://example.org/projects/#{@project.id}/imports/\d+/edit}, last_response['location']
    end

    test "edit import with duplicate keys" do
      import = Import.create(:project => @project, :data => fixture_file_upload('duplicate-keys.csv'))
      import.import!
      get "/projects/#{@project.id}/imports/#{import.id}/edit"
      assert last_response.ok?
    end

    test "update import with duplicate keys" do
      import = Import.create(:project => @project, :data => fixture_file_upload('duplicate-keys.csv'))
      import.import!

      put("/projects/#{@project[:id]}/imports/#{import.id}", { :delete => { "1" => ["1", "2"] }})
      assert last_response.redirect?
      assert_match %r{http://example.org/projects/#{@project[:id]}/resources/\d+}, last_response['location']
    end
  end
end

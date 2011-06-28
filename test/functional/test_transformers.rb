require 'helper'

module CouplerFunctionalTests
  class TestTransformers < Coupler::Test::FunctionalTest
    test "index" do
      visit '/transformers'
      assert_equal 200, page.status_code
    end

    test "new" do
      visit '/transformers/new'
      fill_in('Name', :with => 'noop')
      select('String', :from => 'Allowed Field Types')
      select('String', :from => 'Result Type')
      fill_in('Code', :with => 'value')
      click_button('Submit')
      assert_equal "/transformers", page.current_path
      assert Transformer[:name => 'noop']
    end

    test "failed create" do
      visit '/transformers/new'
      fill_in('Name', :with => '')
      select('String', :from => 'Allowed Field Types')
      select('String', :from => 'Result Type')
      fill_in('Code', :with => 'value')
      click_button('Submit')
      assert page.has_content?("Name is not present")
    end

    test "edit" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      visit "/transformers/#{xformer.id}/edit"
      fill_in('Name', :with => 'foo')
      click_button('Submit')
      assert_equal "/transformers", page.current_path
      xformer.reload
      assert_equal 'foo', xformer.name
    end

    test "failed update" do
      xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      visit "/transformers/#{xformer.id}/edit"
      fill_in('Code', :with => 'foo(')
      click_button('Submit')
      assert page.has_content?("Code has errors")
    end

    #test "preview" do
      #post "/transformers/preview", :transformer => { 'code' => 'value.downcase', 'allowed_types' => %w{string}, 'result_type' => 'string' }
      #assert_equal 200, page.status_code
    #end

    #test "delete" do
      #xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      #delete "/transformers/#{xformer.id}"
      #assert_equal 0, Transformer.filter(:id => xformer.id).count
      #assert last_response.redirect?, last_response.inspect
      #assert_equal "http://example.org/transformers", page.current_path
    #end

    #test "show" do
      #xformer = Transformer.create(:name => 'noop', :code => 'value', :allowed_types => %w{string}, :result_type => 'string')
      #visit "/transformers/#{xformer.id}"
      #assert_equal 200, page.status_code
    #end
  end
end

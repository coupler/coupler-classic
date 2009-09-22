require File.dirname(__FILE__) + '/../../helper'

class TestResources < Test::Unit::TestCase
  def test_resources
    get "/resources"
    assert last_response.ok?
  end

  def test_new_resource
    get "/resources/new"
    assert last_response.ok?

    doc = Nokogiri::HTML(last_response.body)
    assert_equal 1, doc.css('form[action="/resources"]').length
    assert_equal 1, doc.css("select[name='resource[database_id]']").length
    assert_equal 1, doc.css("input[name='resource[table_name]']").length
  end

  def test_create_resource
    database = Factory(:database)
    Coupler::Resource.delete
    assert_equal 0, Coupler::Resource.count
    post "/resources", {
      'resource' => { 'table_name' => 'foo', 'database_id' => database[:id] }
    }
    assert_equal 1, Coupler::Resource.count
    assert last_response.redirect?, "Wasn't redirected"
  end
end

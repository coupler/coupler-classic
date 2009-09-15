require File.dirname(__FILE__) + '/../../helper'

class TestResources < Test::Unit::TestCase
  def test_resources
    get "/resources"
    assert last_response.ok?
  end

  #def test_new_database
    #get "/databases/new"
    #assert last_response.ok?

    #doc = Nokogiri::HTML(last_response.body)
    #assert_equal 1, doc.css('form[action="/databases"]').length
    #assert_equal 1, doc.css("select[name='database[adapter]']").length
    #%w{name host port username password dbname}.each do |name|
      #assert_equal 1, doc.css("input[name='database[#{name}]']").length
    #end
  #end

  #def test_create_database
    #Coupler::Database.delete
    #assert_equal 0, Coupler::Database.count
    #post "/databases", {
      #'database' => {
        #'name' => 'Hogwarts', 'adapter' => 'mysql',
        #'host' => 'localhost', 'port' => '3306',
        #'username' => 'root', 'password' => 'omgponies',
        #'dbname' => 'hogwarts'
      #}
    #}
    #assert_equal 1, Coupler::Database.count
    #assert last_response.redirect?, "Wasn't redirected"
  #end
end

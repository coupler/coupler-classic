require File.dirname(__FILE__) + '/../../helper'

class TestResources < Test::Unit::TestCase
  def setup
    Coupler::Project.delete
    Coupler::Resource.delete
    @project = Factory(:project, :slug => "roflcopter")
  end

  def test_resources
    my_resource = Factory(:resource, :name => "roflsauce", :project => @project)
    nacho_resource = Factory(:resource, :name => "omgponies")

    get "/projects/roflcopter/resources"
    assert last_response.ok?
    assert_match /roflsauce/, last_response.body
    assert_no_match /omgponies/, last_response.body
  end

  def test_new_resource
    get "/projects/roflcopter/resources/new"
    assert last_response.ok?

    doc = Nokogiri::HTML(last_response.body)
    assert_equal 1, doc.css('form[action="/projects/roflcopter/resources"]').length
    assert_equal 1, doc.css("select[name='resource[adapter]']").length
    %w{name host port username password database_name table_name}.each do |name|
      assert_equal 1, doc.css("input[name='resource[#{name}]']").length
    end
  end

  def test_create_resource
    post "/projects/roflcopter/resources", {
      'resource' => {
        'name' => 'roflsauce', 'adapter' => 'mysql',
        'host' => 'localhost', 'port' => '3306',
        'username' => 'root', 'password' => 'omgponies',
        'database_name' => 'hogwarts', 'table_name' => 'foo'
      }
    }
    resource = Coupler::Resource[:name => 'roflsauce', :project_id => @project.id]
    assert resource

    assert last_response.redirect?, "Wasn't redirected"
    follow_redirect!
    assert_equal "http://example.org/projects/roflcopter/resources/#{resource.id}", last_request.url
  end

  def test_show_resource
    resource = Factory(:resource, :name => "roflsauce", :project => @project)

    get "/projects/roflcopter/resources/#{resource.id}"
    assert last_response.ok?
    assert_match /roflsauce/, last_response.body
  end
end

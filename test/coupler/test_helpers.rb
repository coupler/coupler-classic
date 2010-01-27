require File.dirname(__FILE__) + '/../helper'

module Coupler
  class TestHelpers < Test::Unit::TestCase
    include ::Coupler::Helpers

    def test_error_messages_for
      valid_object = mock("valid object", :errors => [])
      assert_equal "", error_messages_for(valid_object)

      invalid_object = mock("invalid object")
      invalid_object.expects(:errors).twice.returns([[:base, ['foo']], [:pants, ['are dirty', 'are smelly']]])
      result = error_messages_for(invalid_object)

      doc = Nokogiri::HTML(result)
      assert (div = doc.at("div.errors"))
      assert (ul = div.at('ul'))

      assert_equal 3, (li = ul.css('li')).length
      assert_equal "foo", li[0].inner_html
      assert_equal "Pants are dirty", li[1].inner_html
      assert_equal "Pants are smelly", li[2].inner_html
    end

    def test_delete_link
      expected = %^<a href="/foo/bar" onclick="if (confirm('Are you sure?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href; var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m); f.submit(); }; return false;">Foo bar</a>^
      assert_equal expected, delete_link("Foo bar", "/foo/bar")
    end
  end
end

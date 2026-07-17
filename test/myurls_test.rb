require 'test_helper'

class MyurlsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Myurls::App
  end

  def test_access
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'myurls'
  end

  def test_xip_host_renders_xip_page
    header 'Host', 'xip.1gb.xyz'
    get '/'

    assert last_response.ok?
    assert_includes last_response.body, '127-0-0-1.xip.1gb.xyz'
    assert_includes last_response.body, 'Put an IP address'
  end
end

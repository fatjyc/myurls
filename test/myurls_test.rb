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
end

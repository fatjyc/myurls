require 'test_helper'

class MyurlsTest < Minitest::Test
  include Rack::Test::Methods

  def test_shorten
    url = "http://abcdefg.com"
    short = Myurls::Utils.shorten url, DateTime.now.to_s
    assert_equal 7, short.size
  end
end

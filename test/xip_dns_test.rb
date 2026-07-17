require 'test_helper'

class XipDnsTest < Minitest::Test
  ZONE = 'xip.1gb.xyz'

  def test_extracts_dotted_ipv4
    assert_equal '127.0.0.1', Myurls::XipDns.extract_ipv4('127.0.0.1.xip.1gb.xyz', ZONE)
    assert_equal '10.20.30.40', Myurls::XipDns.extract_ipv4('app.10.20.30.40.xip.1gb.xyz', ZONE)
  end

  def test_extracts_dashed_ipv4
    assert_equal '127.0.0.1', Myurls::XipDns.extract_ipv4('127-0-0-1.xip.1gb.xyz', ZONE)
    assert_equal '192.168.1.20', Myurls::XipDns.extract_ipv4('app.192-168-1-20.xip.1gb.xyz', ZONE)
  end

  def test_rejects_invalid_or_unrelated_names
    assert_nil Myurls::XipDns.extract_ipv4('999-0-0-1.xip.1gb.xyz', ZONE)
    assert_nil Myurls::XipDns.extract_ipv4('127-0-0-1.example.com', ZONE)
  end

  def test_builds_a_response
    response = Myurls::XipDns.answer(
      query('127-0-0-1.xip.1gb.xyz'),
      zone: ZONE,
      default_ip: '119.28.176.85',
      nameserver: '1gb.xyz'
    )

    assert_equal 1, response.byteslice(6, 2).unpack1('n')
    assert_equal IPAddr.new('127.0.0.1').hton, response.byteslice(-4, 4)
  end

  def test_zone_apex_uses_default_ip
    response = Myurls::XipDns.answer(
      query(ZONE),
      zone: ZONE,
      default_ip: '119.28.176.85',
      nameserver: '1gb.xyz'
    )

    assert_equal IPAddr.new('119.28.176.85').hton, response.byteslice(-4, 4)
  end

  private

  def query(name, type = Myurls::XipDns::TYPE_A)
    header = [1234, 0x0100, 1, 0, 0, 0].pack('n6')
    header + Myurls::XipDns.encode_name(name) + [type, Myurls::XipDns::CLASS_IN].pack('n2')
  end
end

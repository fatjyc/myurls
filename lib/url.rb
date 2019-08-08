# encoding: UTF-8

module Myurls
  module Url
    def self.shorten(url)
      now = DateTime.now.to_s
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), now, url)[10..16]
    end
  end
end

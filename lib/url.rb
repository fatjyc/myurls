# encoding: UTF-8

module Myurls
  module Url
    def self.shorten(url)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), DateTime.now.to_s, url)[10..16]
    end
  end
end

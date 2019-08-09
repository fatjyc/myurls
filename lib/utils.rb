# encoding: UTF-8

module Myurls
  module Utils
    def self.shorten(url, datetime)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), datetime, url)[10..16]
    end
  end
end

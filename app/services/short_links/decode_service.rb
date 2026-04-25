# frozen_string_literal: true

module ShortLinks
  class DecodeService < BaseService

    def initialize(raw_short_url)
      @raw_short_url = raw_short_url
    end

    def call
      code        = UrlNormalizer.extract_code!(@raw_short_url)
      expected_id = ShortCodeCodec.decode(code)
      short_link  = ShortLink.find_by(id: expected_id, code: code)

      raise NotFoundError, 'short URL not found' if short_link.nil?

      short_link
    end

  end
end

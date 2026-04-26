# frozen_string_literal: true

module ShortLinks
  class DecodeService < BaseService

    def initialize(code)
      @code = code
    end

    def call
      cached_short_link = ShortLinks::Cache.read_by_code(@code)

      return cached_short_link if cached_short_link.present?

      expected_id = ShortCodeCodec.decode(@code)
      short_link  = ShortLink.find_by!(id: expected_id, code: @code)
      ShortLinks::Cache.write(short_link)
    end

  end
end

# frozen_string_literal: true

module ShortLinks
  module Cache

    TTL = ENV.fetch('SHORT_LINK_CACHE_TTL_SECONDS', 1.day.to_i).to_i.seconds

    class << self

      def read_by_code(code)
        payload = Rails.cache.read(key_for_code(code))
        payload && short_link_from_payload(payload)
      end

      def write(short_link)
        payload = payload_for(short_link)
        Rails.cache.write(key_for_code(short_link.code), payload, expires_in: TTL)
        short_link
      end

      private

      def key_for_code(code)
        "short_links:code:#{code}"
      end

      def payload_for(short_link)
        {
          id:           short_link.id,
          code:         short_link.code,
          original_url: short_link.original_url,
        }
      end

      def short_link_from_payload(payload)
        ShortLink.new(payload)
      end

    end

  end
end

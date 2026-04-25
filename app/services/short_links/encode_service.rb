# frozen_string_literal: true

module ShortLinks
  class EncodeService < BaseService

    def initialize(raw_url)
      @raw_url = raw_url
    end

    def call
      normalized_url = UrlNormalizer.normalize!(@raw_url)

      find_existing_link(normalized_url) || create_short_link!(normalized_url)
    rescue ActiveRecord::RecordNotUnique
      find_existing_link(normalized_url)
    end

    private

    def find_existing_link(url)
      ShortLink.find_by(original_url: url)
    end

    def create_short_link!(url)
      id   = next_short_link_id
      code = ShortCodeCodec.encode(id)

      ShortLink.create!(id: id, original_url: url, code: code)
    end

    def next_short_link_id
      ShortLink.connection.select_value(
        format("SELECT nextval('%<sequence>s')",
               sequence: ShortLink.sequence_name),
      ).to_i
    end

  end
end

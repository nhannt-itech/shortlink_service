# frozen_string_literal: true

module ShortLinks
  class EncodeService < BaseService

    def initialize(url)
      @url = Addressable::URI.parse(url.strip).normalize.to_s
    end

    def call
      find_existing || create_record
    rescue ActiveRecord::RecordNotUnique
      find_existing
    end

    private

    def find_existing
      ShortLink.find_by(original_url: @url)
    end

    def create_record
      id   = next_short_link_id
      code = ShortCodeCodec.encode(id)

      ShortLink.create!(id: id, original_url: @url, code: code)
    end

    def next_short_link_id
      connection = ShortLink.connection
      quoted_sequence_name = connection.quote(ShortLink.sequence_name)

      connection.select_value("SELECT nextval(#{quoted_sequence_name}::regclass)").to_i
    end

  end
end

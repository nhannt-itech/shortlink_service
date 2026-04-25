# frozen_string_literal: true

module ShortLinks
  class DecodeService < BaseService

    def initialize(code)
      @code = code
    end

    def call
      expected_id = ShortCodeCodec.decode(@code)

      ShortLink.find_by!(id: expected_id, code: @code)
    end

  end
end

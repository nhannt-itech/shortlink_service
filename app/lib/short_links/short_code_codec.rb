# frozen_string_literal: true

module ShortLinks
  class ShortCodeCodec

    MIN_CODE_LENGTH    = 6
    PADDING_CHARACTER  = '0'
    LEADING_PADDING_RE = /\A#{PADDING_CHARACTER}+/

    class << self

      def encode(id)
        Base62Codec.encode(IdObfuscator.obfuscate(id)).rjust(MIN_CODE_LENGTH, PADDING_CHARACTER)
      end

      def decode(code)
        token = code.to_s.strip
        raise DecodeError, 'short code is missing'                      if token.empty?
        raise DecodeError, 'short code contains unsupported characters' unless token.match?(Base62Codec::TOKEN_PATTERN)

        id = IdObfuscator.deobfuscate(Base62Codec.decode(strip_padding(token)))
        raise DecodeError, 'short code is invalid' if id <= 0

        id
      rescue ArgumentError => e
        raise DecodeError, e.message
      end

      private

      def strip_padding(token)
        token.sub(LEADING_PADDING_RE, '').presence || PADDING_CHARACTER
      end

    end

  end
end

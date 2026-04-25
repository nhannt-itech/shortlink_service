# frozen_string_literal: true

module ShortLinks
  class ShortCodeCodec

    MIN_CODE_LENGTH    = 6
    PADDING_CHARACTER  = '0'
    LEADING_PADDING_RE = /\A#{PADDING_CHARACTER}+/

    class << self

      def encode(id)
        obfuscated_id = IdObfuscator.obfuscate(id)
        Base62Codec.encode(obfuscated_id).rjust(MIN_CODE_LENGTH, PADDING_CHARACTER)
      end

      def decode(code)
        base62_decoded = Base62Codec.decode(strip_padding(code.strip))
        IdObfuscator.deobfuscate(base62_decoded)
      end

      private

      def strip_padding(token)
        token.sub(LEADING_PADDING_RE, '').presence || PADDING_CHARACTER
      end

    end

  end
end

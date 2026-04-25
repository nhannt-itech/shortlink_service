# frozen_string_literal: true

module ShortLinks
  class Base62Codec

    ALPHABET       = (('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a).freeze
    ALPHABET_INDEX = ALPHABET.each_with_index.to_h.freeze
    BASE           = ALPHABET.length
    TOKEN_PATTERN  = /\A[0-9a-zA-Z]+\z/

    class << self

      def encode(number)
        value = Integer(number)
        raise ArgumentError, 'number must be non-negative' if value.negative?
        return ALPHABET.first if value.zero?

        chars = []
        while value.positive?
          value, remainder = value.divmod(BASE)
          chars.prepend(ALPHABET[remainder])
        end
        chars.join
      end

      def decode(token)
        token = token.to_s
        raise ArgumentError, 'code contains unsupported characters' unless token.match?(TOKEN_PATTERN)

        token.chars.reduce(0) do |acc, char|
          (acc * BASE) + ALPHABET_INDEX[char]
        end
      end

    end

  end
end

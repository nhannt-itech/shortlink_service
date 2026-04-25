# frozen_string_literal: true

module ShortLinks
  class ShortCodeCodec
    class Base62Codec

      ALPHABET       = (('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a).freeze
      ALPHABET_INDEX = ALPHABET.each_with_index.to_h.freeze
      BASE           = ALPHABET.length

      class << self

        def encode(number)
          return ALPHABET.first if number.zero?

          chars = []
          while number.positive?
            number, remainder = number.divmod(BASE)
            chars.prepend(ALPHABET[remainder])
          end

          chars.join
        end

        def decode(token)
          token.each_char.reduce(0) { |acc, char| (acc * BASE) + ALPHABET_INDEX.fetch(char) }
        end

      end

    end
  end
end

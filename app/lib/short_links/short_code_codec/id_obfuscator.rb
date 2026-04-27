# frozen_string_literal: true

module ShortLinks
  class ShortCodeCodec
    class IdObfuscator

      PRIME               = 0x9E37_79B1_85EB_CA87
      INVERSE             = 0x0887_4934_32BA_DB37
      XOR_KEY             = 0xA5A5_A5A5_5A5A_5A5A
      MASK                = 0xFFFF_FFFF_FFFF_FFFF
      FIRST_SHIFT_BITS    = 33
      SECOND_SHIFT_BITS   = 29
      BIT_WIDTH           = 64

      class << self

        def obfuscate(id)
          n = id.to_i & MASK
          n = mix_xor_right(n, FIRST_SHIFT_BITS)
          n = (n * PRIME) & MASK
          n = mix_xor_right(n, SECOND_SHIFT_BITS)

          n ^ XOR_KEY
        end

        def deobfuscate(code)
          n = code.to_i ^ XOR_KEY
          n = unmix_xor_right(n, SECOND_SHIFT_BITS)
          n = (n * INVERSE) & MASK

          unmix_xor_right(n, FIRST_SHIFT_BITS)
        end

        private

        def mix_xor_right(number, shift_bits)
          (number ^ (number >> shift_bits)) & MASK
        end

        def unmix_xor_right(number, shift_bits)
          value = number & MASK
          step  = shift_bits

          while step < BIT_WIDTH
            value = (value ^ (value >> step)) & MASK
            step *= 2
          end

          value
        end

      end

    end
  end
end

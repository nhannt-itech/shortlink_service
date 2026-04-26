# frozen_string_literal: true

module ShortLinks
  class ShortCodeCodec
    class IdObfuscator

      PRIME    = 0x9E37_79B9
      INVERSE  = 0x1FDA_3B19
      XOR_KEY  = 0x5A17_3F21
      MASK     = 0xFFFF_FFFF

      class << self

        def obfuscate(id)
          n = id.to_i
          n = (n ^ (n >> 16)) & MASK
          n = (n * PRIME)     & MASK
          n = (n ^ (n >> 16)) & MASK

          n ^ XOR_KEY
        end

        def deobfuscate(code)
          n = code.to_i ^ XOR_KEY
          n = (n ^ (n >> 16))  & MASK
          n = (n * INVERSE)    & MASK

          (n ^ (n >> 16)) & MASK
        end

      end

    end
  end
end

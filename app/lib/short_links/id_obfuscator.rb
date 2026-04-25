# frozen_string_literal: true

module ShortLinks
  class IdObfuscator

    XOR_KEY = 0x5A17_3F21

    class << self

      def obfuscate(id)
        id.to_i ^ XOR_KEY
      end

      alias deobfuscate obfuscate

    end

  end
end

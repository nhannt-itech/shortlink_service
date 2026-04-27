# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShortLinks::ShortCodeCodec do
  describe '.encode/.decode' do
    it 'roundtrips IDs through generated short codes' do
      ids = [1, 2, 3, 10, 123, 999_999, (2**31) - 1, 2**40, (2**63) - 1]

      ids.each do |id|
        code = described_class.encode(id)

        expect(described_class.decode(code)).to eq(id)
      end
    end
  end
end

# frozen_string_literal: true

module ShortLinks
  class DecodeContract < Dry::Validation::Contract

    TOKEN_PATTERN   = /\A[0-9a-zA-Z]+\z/
    MAX_CODE_LENGTH = 20

    params do
      required(:code).filled(:string)
    end

    rule(:code) do
      key.failure('is too long') if value.length > MAX_CODE_LENGTH
      key.failure('must contain only alphanumeric characters') unless value.match?(TOKEN_PATTERN)
    end

  end
end

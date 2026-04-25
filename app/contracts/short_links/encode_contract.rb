# frozen_string_literal: true

module ShortLinks
  class EncodeContract < Dry::Validation::Contract

    MAX_URL_LENGTH = 2048

    params do
      required(:url).filled(:string)
    end

    rule(:url) do
      key.failure("is too long (maximum #{MAX_URL_LENGTH} characters)") and next if value.length > MAX_URL_LENGTH

      begin
        uri = URI.parse(value)

        key.failure('must be a valid http/https URL') unless %w[http https].include?(uri.scheme) && uri.host.present?
      rescue URI::InvalidURIError
        key.failure('must be a valid URL')
      end
    end

  end
end

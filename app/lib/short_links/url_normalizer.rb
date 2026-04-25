# frozen_string_literal: true

module ShortLinks
  class UrlNormalizer

    SUPPORTED_SCHEMES   = %w[http https].freeze
    LEADING_SLASH_REGEX = %r{\A/}

    class << self

      def normalize!(url)
        uri = URI.parse(url.to_s.strip)

        unless SUPPORTED_SCHEMES.include?(uri.scheme) && uri.host.present?
          raise InvalidUrlError, 'url must be an absolute http/https URL'
        end

        uri.to_s
      rescue URI::InvalidURIError
        raise InvalidUrlError, 'url must be a valid URL'
      end

      def extract_code!(short_url)
        input = short_url.to_s.strip
        raise DecodeError, 'short_url is required' if input.empty?

        return input if valid_token?(input)

        path = URI.parse(input).path.to_s.sub(LEADING_SLASH_REGEX, '')
        return path if valid_token?(path)

        raise DecodeError, 'short_url does not contain a valid short code'
      rescue URI::InvalidURIError
        raise DecodeError, 'short_url is not a valid URL or short code'
      end

      private

      def valid_token?(value)
        value.match?(Base62Codec::TOKEN_PATTERN)
      end

    end

  end
end

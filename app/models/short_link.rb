# frozen_string_literal: true

class ShortLink < ApplicationRecord

  URL_SCHEMES = %w[http https].freeze

  validates :original_url, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[0-9a-zA-Z]+\z/ }
  validate :original_url_is_http_or_https

  def shortened_url(base_url)
    "#{base_url}/#{code}"
  end

  private

  def original_url_is_http_or_https
    uri = URI.parse(original_url.to_s)

    return if URL_SCHEMES.include?(uri.scheme) && uri.host.present?

    errors.add(:original_url, 'must be an absolute http/https URL')
  rescue URI::InvalidURIError
    errors.add(:original_url, 'must be a valid URL')
  end

end

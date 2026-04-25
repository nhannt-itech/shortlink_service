# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ShortLinks API', type: :request do # rubocop:disable RSpecRails/InferredSpecType
  describe 'POST /encode' do
    it 'returns a deterministic short url for valid input' do
      # Arrange
      url = 'https://codesubmit.io/library/react'

      # Act
      post '/encode', params: { url: url }, as: :json

      # Assert
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('short_url')).to match(%r{\Ahttp://www.example.com/[0-9a-zA-Z]{6,}\z})
    end

    it 'is idempotent for the same normalized url' do
      # Arrange
      url = 'https://example.com/docs?q=1'

      # Act
      post '/encode', params: { url: url }, as: :json
      first_short_url = response.parsed_body.fetch('short_url')
      post '/encode', params: { url: url }, as: :json
      second_short_url = response.parsed_body.fetch('short_url')

      # Assert
      expect(first_short_url).to eq(second_short_url)
    end

    it 'rejects unsupported url schemes' do
      # Arrange
      payload = { url: 'ftp://example.com/file.txt' }

      # Act
      post '/encode', params: payload, as: :json

      # Assert
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch('error')).to include('absolute http/https URL')
    end
  end

  describe 'POST /decode' do
    it 'returns original url for an encoded short url' do
      # Arrange
      original_url = 'https://codesubmit.io/library/react'
      post '/encode', params: { url: original_url }, as: :json
      short_url = response.parsed_body.fetch('short_url')

      # Act
      post '/decode', params: { short_url: short_url }, as: :json

      # Assert
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('url')).to eq(original_url)
    end

    it 'accepts a raw short code' do
      # Arrange
      original_url = 'https://example.com/alpha'
      post '/encode', params: { url: original_url }, as: :json
      code = response.parsed_body.fetch('short_url').split('/').last

      # Act
      post '/decode', params: { short_url: code }, as: :json

      # Assert
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('url')).to eq(original_url)
    end

    it 'returns not found for unknown short url' do
      # Arrange
      payload = { short_url: 'http://short.ly/ABC123' }

      # Act
      post '/decode', params: payload, as: :json

      # Assert
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.fetch('error')).to eq('short URL not found')
    end
  end
end

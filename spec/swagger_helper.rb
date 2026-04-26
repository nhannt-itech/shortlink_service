# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/openapi.yaml' => {
      openapi:    '3.0.1',
      info:       {
        title:       'ShortLink API',
        version:     'v1',
        description: 'URL encoding and decoding API',
      },
      paths:      {},
      components: {
        schemas: {
          EncodeRequest:    {
            type:       :object,
            required:   %w[url],
            properties: {
              url: { type: :string, format: :uri },
            },
          },
          EncodeResponse:   {
            type:       :object,
            required:   %w[short_url],
            properties: {
              short_url: { type: :string, format: :uri },
            },
          },
          DecodeRequest:    {
            type:       :object,
            required:   %w[code],
            properties: {
              code: { type: :string },
            },
          },
          DecodeResponse:   {
            type:       :object,
            required:   %w[url],
            properties: {
              url: { type: :string, format: :uri },
            },
          },
          ErrorResponse:    {
            type:       :object,
            required:   %w[errors],
            properties: {
              errors: {
                type:                 :object,
                additionalProperties: {
                  type:  :array,
                  items: { type: :string },
                },
              },
            },
          },
          NotFoundResponse: {
            type:       :object,
            required:   %w[error],
            properties: {
              error: { type: :string, example: 'Not Found' },
            },
          },
        },
      },
    },
  }

  config.openapi_format = :yaml
end

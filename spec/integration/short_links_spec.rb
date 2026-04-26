# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'ShortLinks API', type: :request do # rubocop:disable RSpec/EmptyExampleGroup,RSpecRails/InferredSpecType
  path '/encode' do
    post 'Create short URL from original URL' do
      tags 'ShortLinks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/EncodeRequest' }

      response '200', 'short URL is generated' do
        schema '$ref' => '#/components/schemas/EncodeResponse'
        let(:payload) { { url: 'https://codesubmit.io/library/react' } }

        run_test! do
          expect(response.parsed_body.fetch('short_url')).to match(%r{\Ahttp://www.example.com/[0-9a-zA-Z]{6,}\z})
        end
      end

      response '200', 'same normalized URL returns the same short URL' do
        schema '$ref' => '#/components/schemas/EncodeResponse'
        let(:payload) { { url: 'https://example.com/docs?q=1' } }

        run_test! do
          first_short_url = response.parsed_body.fetch('short_url')

          post '/encode', params: payload, as: :json
          second_short_url = response.parsed_body.fetch('short_url')

          expect(first_short_url).to eq(second_short_url)
        end
      end

      response '200', 'URL variants normalize to the same short URL' do
        schema '$ref' => '#/components/schemas/EncodeResponse'
        let(:payload) { { url: 'HTTPS://Example.COM:443/docs/../docs?q=1' } }

        run_test! do
          first_short_url = response.parsed_body.fetch('short_url')

          post '/encode', params: { url: 'https://example.com/docs?q=1' }, as: :json
          second_short_url = response.parsed_body.fetch('short_url')

          expect(first_short_url).to eq(second_short_url)
        end
      end

      response '422', 'URL scheme is invalid' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:payload) { { url: 'ftp://example.com/file.txt' } }

        run_test! do
          expect(response.parsed_body.fetch('errors').fetch('url')).to include('must be a valid http/https URL')
        end
      end

      response '422', 'required URL parameter is missing' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:payload) { {} }

        run_test! do
          expect(response.parsed_body.fetch('errors').fetch('url')).to include('is missing')
        end
      end
    end
  end

  path '/decode' do
    post 'Decode short URL or short code to original URL' do
      tags 'ShortLinks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/DecodeRequest' }

      response '200', 'original URL is returned from short code' do
        schema '$ref' => '#/components/schemas/DecodeResponse'
        let(:payload) do
          post '/encode', params: { url: 'https://codesubmit.io/library/react' }, as: :json
          code = response.parsed_body.fetch('short_url').split('/').last
          { code: code }
        end

        run_test! do
          expect(response.parsed_body.fetch('url')).to eq('https://codesubmit.io/library/react')
        end
      end

      response '200', 'raw short code is accepted' do
        schema '$ref' => '#/components/schemas/DecodeResponse'
        let(:payload) do
          post '/encode', params: { url: 'https://example.com/alpha' }, as: :json
          code = response.parsed_body.fetch('short_url').split('/').last
          { code: code }
        end

        run_test! do
          expect(response.parsed_body.fetch('url')).to eq('https://example.com/alpha')
        end
      end

      response '404', 'short URL does not exist' do
        schema '$ref' => '#/components/schemas/NotFoundResponse'
        let(:payload) { { code: 'ABC123' } }

        run_test! do
          expect(response.parsed_body.fetch('error')).to eq('Not Found')
        end
      end

      response '422', 'short code format is invalid' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:payload) { { code: 'invalid code' } }

        run_test! do
          expect(
            response.parsed_body.fetch('errors').fetch('code'),
          ).to include('must contain only alphanumeric characters')
        end
      end

      response '422', 'required code parameter is missing' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:payload) { {} }

        run_test! do
          expect(response.parsed_body.fetch('errors').fetch('code')).to include('is missing')
        end
      end
    end
  end
end

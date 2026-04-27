# frozen_string_literal: true

if defined?(Rswag::Ui)
  Rswag::Ui.configure do |c|
    c.openapi_endpoint '/api-docs/v1/openapi.yaml', 'ShortLink API V1'
    c.config_object['defaultModelsExpandDepth'] = -1
  end
end

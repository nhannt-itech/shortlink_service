# frozen_string_literal: true

module ApiValidatable

  extend ActiveSupport::Concern

  class ValidationError < StandardError

    attr_reader :errors

    def initialize(errors)
      @errors = errors

      super('Validation Failed')
    end

  end

  def validate_with!(contract_class, input_params = params.to_unsafe_h)
    clean_input = input_params.except(:controller, :action)
    result      = contract_class.new.call(clean_input)

    raise ValidationError, result.errors.to_h if result.failure? # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods

    result.to_h
  end

  private

  def handle_validation_error(err)
    render json: { errors: err.errors }, status: :unprocessable_content
  end

end

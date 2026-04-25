# frozen_string_literal: true

class ApplicationController < ActionController::API

  include ApiValidatable

  rescue_from StandardError, with: :handle_internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ValidationError, with: :handle_validation_error

  private

  def render_success(data)
    render json: data, status: :ok
  end

  def handle_not_found
    render json: { error: 'Not Found' }, status: :not_found
  end

  def handle_internal_server_error(exception)
    Rails.logger.error(exception.full_message)

    render json: { error: 'Internal Server Error' }, status: :internal_server_error
  end

end

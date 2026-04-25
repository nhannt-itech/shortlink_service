# frozen_string_literal: true

class ApplicationController < ActionController::API

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity

  rescue_from ShortLinks::DecodeError, with: :render_bad_request
  rescue_from ShortLinks::InvalidUrlError, with: :render_unprocessable_entity_message
  rescue_from ShortLinks::NotFoundError, with: :render_not_found

  private

  def render_bad_request(error)
    render_error(error.message, :bad_request)
  end

  def render_unprocessable_entity_message(error)
    render_error(error.message, :unprocessable_entity)
  end

  def render_unprocessable_entity(error)
    render_error(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  def render_not_found(error)
    render_error(error.message, :not_found)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end

end

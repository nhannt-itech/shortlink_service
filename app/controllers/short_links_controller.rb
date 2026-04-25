# frozen_string_literal: true

class ShortLinksController < ApplicationController

  def encode
    short_link = ShortLinks::EncodeService.call(params.require(:url))

    render json: { short_url: short_link.shortened_url(request.base_url) }, status: :ok
  end

  def decode
    short_link = ShortLinks::DecodeService.call(params.require(:short_url))

    render json: { url: short_link.original_url }, status: :ok
  end

end

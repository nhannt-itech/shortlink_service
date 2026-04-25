# frozen_string_literal: true

class ShortLinksController < ApplicationController

  def encode
    encode_params = validate_with!(ShortLinks::EncodeContract)

    short_link = ShortLinks::EncodeService.call(encode_params[:url])

    render_success({ short_url: short_link.shortened_url(request.base_url) })
  end

  def decode
    decode_params = validate_with!(ShortLinks::DecodeContract)

    short_link = ShortLinks::DecodeService.call(decode_params[:code])

    render_success({ url: short_link.original_url })
  end

end

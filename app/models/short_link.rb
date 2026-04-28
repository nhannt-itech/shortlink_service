# frozen_string_literal: true

class ShortLink < ApplicationRecord

  def shortened_url(base_url)
    "#{base_url}/#{code}"
  end

end

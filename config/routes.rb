# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Api::Engine => '/api-docs' if defined?(Rswag::Api::Engine)
  mount Rswag::Ui::Engine => '/api-docs' if defined?(Rswag::Ui::Engine)

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  post 'encode', to: 'short_links#encode'
  post 'decode', to: 'short_links#decode'
end

# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Health check for the load balancer: 200 if the app boots, 500 otherwise.
  get "up", to: "rails/health#show", as: :rails_health_check

  # ValidSignador routes (outside of Decidim engine)
  namespace :valid_signador do
    get "/callback", to: "callbacks#create", as: :callback
  end

  mount Decidim::Core::Engine => "/"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end

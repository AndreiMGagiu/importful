require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  get "up" => "rails/health#show", as: :rails_health_check
  resources :imports, only: [ :create, :new ]
  root "imports#new"
  namespace :api do
    namespace :v1 do
      resources :s3_webhooks, only: :create
    end
  end
end

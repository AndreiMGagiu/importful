require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  get "up" => "rails/health#show", as: :rails_health_check
  resources :imports, only: [ :create, :new ]
  root 'home#index'
  resources :dashboard, only: [:index]
  get 'dashboard', to: 'dashboard#index'
  get 'dashboard/affiliates', to: 'dashboard#affiliates'
  get 'dashboard/stats', to: 'dashboard#stats'

  # Import Audit routes
  get 'dashboard/import_audits', to: 'import_audits#index'
  get 'dashboard/import_audits/:id', to: 'import_audits#show', as: 'import_audit'
  
  namespace :api do
    namespace :v1 do
      resources :s3_webhooks, only: :create
    end
  end
end

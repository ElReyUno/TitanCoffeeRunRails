Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  resources :products, only: [ :index ]
  resources :orders, only: [ :index, :show, :create ]

  namespace :admin do
    resources :sales, only: [ :index ]
    resources :products
    resources :orders, only: [ :index, :show, :update ]
  end

  # API routes for AJAX requests
  namespace :api do
    namespace :v1 do
      resources :cart_items, only: [ :create, :update, :destroy ]
      resources :sales, only: [ :index ]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end

Rails.application.routes.draw do
  root 'payments#index'
  devise_for :users
  resources :users, only: [:show]
  resources :payments
  resources :subscriptions
  resource :verification, only: [:edit, :update]
end

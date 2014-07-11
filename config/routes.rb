Rails.application.routes.draw do
  root 'static_pages#index'
  devise_for :users
  resources :users, only: [:show]
  resources :subscriptions, only: [:new, :create]
  resource :verification, only: [:edit, :update]
end

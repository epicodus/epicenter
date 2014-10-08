Rails.application.routes.draw do
  root 'static_pages#index'
  devise_for :users
  resource :bank_account, only: [:new, :create]
  resource :verification, only: [:edit, :update]
  resources :payments, only: [:index]
  resources :upfront_payments, only: [:new, :create]
  resources :recurring_payments, only: [:new, :create]
end

Rails.application.routes.draw do
  root 'static_pages#index'
  devise_for :users
  resources :bank_accounts, only: [:new, :create]
  resource :verification, only: [:edit, :update]
  resources :payments, only: [:index]
end

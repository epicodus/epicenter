Rails.application.routes.draw do
  root 'payments#index'
  devise_for :users
  resources :payments
  resources :subscriptions
end

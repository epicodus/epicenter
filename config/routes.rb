Rails.application.routes.draw do
  root 'payments#index'
  devise_for :users, :controllers => { :registrations => "registrations" }
  resources :payments
  resources :subscriptions
end

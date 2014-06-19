Rails.application.routes.draw do
  root 'payments#index'
  devise_for :users
end

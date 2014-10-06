Rails.application.routes.draw do
  root 'static_pages#index'
  devise_for :users
  resource :bank_account, only: [:new, :create]
  resource :verification, only: [:edit, :update]
  resources :payments, only: [:index]
  get 'attendance', to: 'attendance_records#index', as: 'attendance'
  resources :attendance_records, only: [:create, :destroy]
end

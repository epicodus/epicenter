Rails.application.routes.draw do
  root 'static_pages#index'
  get 'attendance', to: 'attendance_records#index', as: 'attendance'
  get 'payment_method', to: 'static_pages#payment_method', as: 'payment_method'

  devise_for :users, expect: :registrations
  devise_for :student, expect: :sessions

  resource :bank_account, only: [:new, :create]
  resource :credit_card, only: [:new, :create]
  resource :verification, only: [:edit, :update]
  resources :payments, only: [:index]
  resources :upfront_payments, only: [:create]
  resources :recurring_payments, only: [:create]
  resources :attendance_records, only: [:create, :destroy]
  resources :cohorts, only: [] do
    resource :attendance_statistics, only: [:show]
  end

  resources :assessments do
    resources :submissions, only: [:index, :create, :update]
  end

  resources :submissions, only: [] do
    resources :reviews, only: [:new, :create]
  end

  resources :assessments
end

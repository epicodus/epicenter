Rails.application.routes.draw do
  root 'static_pages#index'
  get 'attendance', to: 'attendance_records#index', as: 'attendance'

  devise_for :student
  devise_for :admins, skip: :registrations

  resources :students, only: [:update]
  resources :payment_methods, only: [:index, :new]
  resources :bank_accounts, only: [:new, :create] do
    resource :verification, only: [:edit, :update]
  end
  resource :credit_card, only: [:new, :create]
  resources :payments, only: [:index]
  resources :upfront_payments, only: [:create]
  resources :recurring_payments, only: [:create]
  resources :attendance_records, only: [:create, :destroy]
  resources :cohorts, only: [] do
    resources :attendance_statistics, only: [:index]
  end

  resource :attendance_statistics, only: [:show]

  resources :assessments do
    resources :submissions, only: [:index, :create, :update]
  end

  resources :submissions, only: [] do
    resources :reviews, only: [:new, :create]
  end

  resources :assessments
end

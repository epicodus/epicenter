Rails.application.routes.draw do
  root 'static_pages#index'
  get 'attendance', to: 'attendance_records#index', as: 'attendance'

  devise_for :student
  devise_for :admins, skip: :registrations

  resources :students, only: [:update]
  resources :admins, only: [:update]
  resources :payment_methods, only: [:index, :new]
  resources :bank_accounts, only: [:new, :create] do
    resource :verification, only: [:edit, :update]
  end
  resource :credit_card, only: [:new, :create]
  resource :certificate, only: [:show]
  resource :transcript, only: [:show]
  resources :payments, only: [:index]
  resources :upfront_payments, only: [:create]
  resources :recurring_payments, only: [:create]
  resources :attendance_records, only: [:create, :destroy]
  resources :attendance_record_amendments, only: [:new, :create]
  resources :cohorts, except: [:show, :index] do
    resources :attendance_statistics, only: [:index]
    resources :assessments, only: [:index]
  end
  resources :companies, only: [:index, :show]

  resource :attendance_statistics, only: [:show]

  resources :assessments, except: [:index] do
    resources :submissions, only: [:index, :create, :update]
    resource :report, only: [:show], to: 'assessment_reports#show'
    collection do
      patch :update_multiple, :path => ''
    end
  end

  resources :submissions, only: [] do
    resources :reviews, only: [:new, :create]
  end

  resources :balanced_callbacks, only: [:create]
end

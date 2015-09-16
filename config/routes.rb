Rails.application.routes.draw do
  root 'static_pages#index'
  get 'attendance', to: 'attendance_records#index', as: 'attendance'

  devise_for :student, :controllers => { :invitations => 'invitations', :registrations => 'registrations' }
  devise_for :admins, skip: :registrations

  resources :students, only: [:show, :update]
  resources :admins, only: [:update]
  resources :payment_methods, only: [:index, :new]
  resources :bank_accounts, only: [:new, :create, :edit, :update]
  resource :credit_card, only: [:new, :create]
  resource :certificate, only: [:show]
  resource :transcript, only: [:show]
  resources :payments, only: [:index]
  resources :upfront_payments, only: [:create]
  resources :recurring_payments, only: [:create]
  resources :attendance_records, only: [:create, :update, :destroy]
  resources :attendance_record_amendments, only: [:new, :create]
  resources :cohorts, except: [:show, :index] do
    resources :attendance_statistics, only: [:index]
    resources :code_reviews, only: [:index]
    resources :internships
    resources :students, only: [:index]
  end
  resources :ratings, only: [:create]
  resources :companies

  resource :attendance_statistics, only: [:show]

  resources :code_reviews, except: [:index] do
    resources :submissions, only: [:index, :create, :update]
    resource :report, only: [:show], to: 'code_review_reports#show'
    collection do
      patch :update_multiple, :path => ''
    end
  end

  resources :submissions, only: [] do
    resources :reviews, only: [:new, :create]
  end

  resources :stripe_callbacks, only: [:create]

  resources :signatures, only: [:create] do
    collection do
      resources :enrollment_agreement, only: [:new]
      resources :code_of_conduct, only: [:new]
      resources :refund_policy, only: [:new]
    end
  end

  resources :pair_attendance_records, only: [:create] do
    collection do
      delete :destroy_multiple, :path => ''
    end
  end
end

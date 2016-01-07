Rails.application.routes.draw do
  root 'static_pages#index'
  get 'sign_out', to: 'attendance_sign_out#new'

  devise_for :student, :controllers => { :invitations => 'invitations', :registrations => 'registrations', sessions: 'student/sessions' }
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
  resources :attendance_record_amendments, only: [:new, :create]
  resources :courses, except: [:show, :index] do
    resources :attendance_statistics, only: [:index, :create]
    resources :code_reviews, only: [:index]
    resources :internships
    resources :students, only: [:index]
    resources :day_attendance_records, only: [:index]
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

  resource :code_review_copy, only: [:create]
  resource :random_pairs, only: [:show]
  resources :enrollments, only: [:create, :destroy]
  resources :sign_out, controller: 'attendance_sign_out', only: [:create]
end

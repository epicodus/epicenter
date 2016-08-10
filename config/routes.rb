Rails.application.routes.draw do
  devise_scope :user do
    root 'users/sessions#new'
  end
  get 'sign_out', to: 'attendance_sign_out#new'
  get 'welcome', to: 'static_pages#show'
  get 'auth/:provider/callback', to: 'omniauth_callbacks#create'

  devise_for :student, controllers: { invitations: 'invitations', registrations: 'registrations' }
  devise_for :admins, skip: :registrations
  devise_for :companies, controllers: { registrations: 'registrations' }, skip: :invitations
  devise_for :users, controllers: { sessions: 'users/sessions' }, skip: [:invitations, :registrations]

  resources :students, only: [:index, :update] do
    resources :courses, only: [:index]
    resources :payments, only: [:index, :create]
  end
  resources :admins, only: [:update]
  resources :payment_methods, only: [:index, :new]
  resources :bank_accounts, only: [:new, :create, :edit, :update]
  resource :credit_card, only: [:new, :create]
  resource :certificate, only: [:show]
  resource :transcript, only: [:show]
  resources :payments, only: [:update]
  resources :upfront_payments, only: [:create]
  resources :attendance_record_amendments, only: [:new, :create]
  resources :internships, only: [:index, :edit, :update]
  resources :courses, except: [:destroy] do
    resources :code_reviews do
      resource :report, only: [:show], to: 'code_review_reports#show'
    end
    resources :internships, only: [:show]
    resources :students, only: [:show]
    resources :day_attendance_records, only: [:index, :create]
  end
  resources :ratings, only: [:create]
  resources :companies, only: [:show]

  resources :code_reviews, except: [:index] do
    resources :submissions, only: [:index, :create, :update]
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
  resource :sign_out, controller: 'attendance_sign_out', only: [:create]
  resource :course_internships, only: [:create, :destroy]
  resource :interview_assignments, only: [:destroy] do
    collection do
      post :create_multiple, path: ''
    end
    collection do
      patch :update_multiple, path: ''
    end
  end
  resources :internship_assignments, only: [:create, :destroy]
end

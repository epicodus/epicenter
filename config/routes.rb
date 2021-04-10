Rails.application.routes.draw do
  devise_scope :user do
    root 'users/sessions#new'
  end
  get 'sign_in', to: 'attendance_sign_in_remote#new'
  get 'sign_out', to: 'pair_feedbacks#new'

  get 'auth/:provider/callback', to: 'omniauth_callbacks#create'

  devise_for :student, controllers: { invitations: 'invitations', registrations: 'registrations' }
  devise_for :admins, skip: :registrations
  devise_for :companies, controllers: { registrations: 'registrations' }, skip: :invitations
  devise_for :users, controllers: { sessions: 'users/sessions' }, skip: [:invitations, :registrations]

  resources :students, only: [:index, :edit, :update, :destroy] do
    resources :courses, only: [:index]
    resources :payments, only: [:index, :create]
    resources :cost_adjustments, only: [:create, :destroy]
    resources :attendance_records, only: [:index]
    resource :restore, only: [:update], to: 'student_restore#update'
    resource :add_course, only: [:update], to: 'add_course#update'
    resource :transcript, only: [:show]
    resource :certificate, only: [:show]
    resources :daily_submissions, only: [:index, :create]
    resources :peer_evaluations, only: [:index, :new, :create, :show]
    resources :pair_feedbacks, only: [:index]
    resource :probation, only: [:edit, :update]
  end
  resources :admins, only: [:update]
  resources :payment_methods, only: [:index, :new]
  resources :bank_accounts, only: [:new, :create, :edit, :update]
  resource :credit_card, only: [:new, :create]
  resource :certificate, only: [:show]
  resource :transcript, only: [:show]
  resource :roster, only: [:show]
  resources :payments, only: [:update]
  resources :upfront_payments, only: [:create]
  resources :attendance_record_amendments, only: [:new, :create]
  resources :internships, only: [:index, :edit, :update]
  resources :cohorts, except: [:destroy]
  resources :courses, except: [:destroy] do
    resource :export, only: [:show], to: 'course_export#show'
    resources :code_reviews, except: [:destroy] do
      resource :report, only: [:show], to: 'code_review_reports#show'
    end
    resources :internships, only: [:show]
    resources :students, only: [:show]
    resources :day_attendance_records, only: [:index, :create]
    resources :ratings, only: [:index]
    resources :peer_evaluations, only: [:index]
    resource :daily_submissions, only: [:show]
    resource :meeting, only: [:new, :create]
  end
  resources :ratings, only: [:create]
  resources :companies, only: [:show]

  resources :code_reviews, only: [:destroy] do
    resource :export, only: [:show], to: 'code_review_export#show'
    resources :submissions, only: [:index, :create, :update]
    collection do
      patch :update_multiple, :path => ''
    end
  end

  resources :submissions, only: [] do
    resources :reviews, only: [:new, :create, :update]
  end

  resources :stripe_callbacks, only: [:create]
  resources :payment_callbacks, only: [:create]
  resources :invitation_callbacks, only: [:create]
  resources :withdraw_callbacks, only: [:create]

  resources :signatures, only: [:create] do
    collection do
      resources :code_of_conduct, only: [:new, :create]
      resources :refund_policy, only: [:new, :create]
      resources :complaint_disclosure, only: [:new, :create]
      resources :enrollment_agreement, only: [:new, :create]
      resources :student_internship_agreement, only: [:new, :create]
    end
  end

  resource :code_review_copy, only: [:create]
  resource :random_pairs, only: [:show]
  resources :enrollments, only: [:create, :destroy]
  resource :sign_in, controller: 'attendance_sign_in_remote', only: [:create]
  resource :sign_out, controller: 'pair_feedbacks', only: [:create]
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

  resources :demographics, only: [:new, :create]

  resources :github_callbacks, only: [:create]

  resources :peer_evaluations, only: [:new]

  resource :pair_feedbacks, only: [:new, :create]

  resource :survey, only: [:new, :create]

  get 'reports', to: 'reports#index'
  resource :reports, only: [:index] do
    resources :teachers, only: [:index, :show]
  end
end

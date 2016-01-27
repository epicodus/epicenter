FactoryGirl.define do
  factory :admin do
    sequence(:name) { |n| "Admin Brown #{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password "password"
    password_confirmation "password"
    association :current_course, factory: :course
  end

  factory :attendance_record do
    student

    factory :on_time_attendance_record do
      tardy false
      left_early false
    end
  end


  factory :bank_account do
    student
    stripe_token({
      :object => 'bank_account',
      :country => 'US',
      :account_number => '000123456789',
      :routing_number => '110000000'
    })

    factory :verified_bank_account do
      after(:create) do |bank_account|
        bank_account.student.stripe_customer.sources.data.each do |payment|
          if payment.object =='bank_account'
            payment.verify(amounts: [32, 45])
          end
        end
        bank_account.ensure_primary_method_exists
      end
      verified true
    end
  end

  factory :code_review do
    sequence(:title) { |n| "code_review #{n}" }
    course

    before(:create) do |code_review|
      code_review.objectives << build(:objective)
    end
  end

  factory :course do
    description 'Current course'
    class_days (Time.zone.now.to_date.beginning_of_week..(Time.zone.now.to_date + 4.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? }
    start_time '8:00 AM'
    end_time '5:00 PM'

    factory :past_course do
      class_days ((Time.zone.now.to_date - 18.weeks).beginning_of_week..(Time.zone.now.to_date - 14.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? }
    end

    factory :future_course do
      class_days ((Time.zone.now.to_date + 4.weeks).beginning_of_week..(Time.zone.now.to_date + 8.weeks).beginning_of_week).select { |day| day if !day.saturday? && !day.sunday? }
    end

    factory :part_time_course do
      start_time '6:00 PM'
      end_time '9:00 PM'
    end
  end

  factory :credit_card do
    student
    stripe_token({
      :object => 'card',
      :number => '4242424242424242',
      :exp_month => '12',
      :exp_year => '2020',
      :cvv => '123'
    })
  end

  factory :grade do
    factory :passing_grade do
      association :score, factory: :passing_score
    end

    factory :failing_grade do
      association :score, factory: :failing_score
    end

    factory :in_between_grade do
      association :score, factory: :in_between_score
    end
  end

  factory :invalid_credit_card, class: CreditCard do
    student
    stripe_token({
      :object => 'card',
      :number => '4242424242424241',
      :exp_month => '12',
      :exp_year => '2020',
      :cvv => '123'
    })
  end

  factory :payment do
    association :student, factory: :user_with_verified_bank_account
    amount 100
    association :payment_method, factory: :verified_bank_account
  end

  factory :payment_with_credit_card, class: Payment do
    association :student, factory: :user_with_credit_card
    amount 100
    association :payment_method, factory: :credit_card
  end

  factory :plan do
    name "summer 2014"

    factory :recurring_plan_with_upfront_payment do
      upfront_amount 200_00
      recurring_amount 600_00
      total_amount 5000_00
    end

    factory :upfront_payment_only_plan do
      upfront_amount 3400_00
      recurring_amount 0
      total_amount 3400_00
    end

    factory :recurring_plan_with_no_upfront_payment do
      upfront_amount 0
      recurring_amount 625_00
      total_amount 5000_00
    end
  end

  factory :objective do
    content 'Continue meeting all the objectives from previous code reviews'
  end

  factory :review do
    note 'Great job!'
    submission

    factory :passing_review do
      after(:create) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryGirl.create(:passing_grade, review: review, objective: objective)
        end
      end
    end

    factory :failing_review do
      after(:create) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryGirl.create(:failing_grade, review: review, objective: objective)
        end
      end
    end

    factory :in_between_review do
      after(:create) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryGirl.create(:in_between_grade, review: review, objective: objective)
        end
      end
    end
  end

  factory :score do
    sequence(:description) { |n| "Meets expectations #{n} of the time" }

    factory :failing_score do
      value 1
    end

    factory :passing_score do
      value 3
    end

    factory :in_between_score do
      value 2
    end
  end

  factory :signature do
    student

    factory :completed_code_of_conduct do
      type CodeOfConduct
      is_complete true
    end

    factory :completed_refund_policy do
      type RefundPolicy
      is_complete true
    end

    factory :completed_enrollment_agreement do
      type EnrollmentAgreement
      is_complete true
    end
  end

  factory :student do
    course
    association :plan, factory: :recurring_plan_with_upfront_payment
    sequence(:name) { |n| "Example Brown #{n}" }
    sequence(:email) { |n| "student#{n}@example.com" }
    password "password"
    password_confirmation "password"

    factory :unenrolled_student do
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
        enrollment = Enrollment.find_by(student_id: student.id)
        enrollment.destroy
      end
    end

    factory :part_time_student do
      association :course, factory: :part_time_course
    end

    factory :user_with_unverified_bank_account do
      after(:create) do |student|
        create(:bank_account, student: student)
      end
    end

    factory :user_with_credit_card do
      after(:create) do |student|
        create(:credit_card, student: student)
      end
    end

    factory :user_with_invalid_credit_card do
      after(:create) do |student|
        create(:invalid_credit_card, student: student)
      end
    end

    factory :user_with_verified_bank_account do
      after(:create) do |student|
        create(:verified_bank_account, student: student)
      end

      factory :user_with_recurring_active do
        recurring_active true
        after(:create) do |student|
          create(:payment, student: student)
        end
      end

      factory :user_with_recurring_not_due do
        recurring_active true
        after(:create) do |student|
          create(:payment, student: student, created_at: 2.weeks.ago)
        end
      end

      factory :user_with_recurring_due do
        recurring_active true
        after(:create) do |student|
          create(:payment, student: student, created_at: 1.month.ago)
        end
      end

      factory :user_with_upfront_payment do
        after(:create) do |student|
          student.make_upfront_payment
        end
      end

    end

    factory :user_with_all_documents_signed do
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
      end
    end

    factory :user_with_all_documents_signed_and_verified_bank_account do
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
        create(:verified_bank_account, student: student)
      end
    end

    factory :user_with_score_of_10 do
      after(:create) do |student|
        submission = create(:submission, student: student)
        review = create(:passing_review, submission: submission)
        create(:passing_grade, review: review, objective: review.submission.code_review.objectives.first)
        create(:passing_grade, review: review, objective: review.submission.code_review.objectives.first)
        create(:failing_grade, review: review, objective: review.submission.code_review.objectives.first)
      end
    end

    factory :user_with_score_of_9 do
      after(:create) do |student|
        submission = create(:submission, student: student)
        review = create(:passing_review, submission: submission)
        create(:passing_grade, review: review, objective: review.submission.code_review.objectives.first)
        create(:passing_grade, review: review, objective: review.submission.code_review.objectives.first)
      end
    end

    factory :user_with_score_of_6 do
      after(:create) do |student|
        submission = create(:submission, student: student)
        review = create(:passing_review, submission: submission)
        create(:passing_grade, review: review, objective: review.submission.code_review.objectives.first)
      end
    end
  end

  factory :submission do
    link 'http://github.com'
    code_review
    student
  end

  factory :company do
    sequence(:name) { |n| "#{n} labs" }
    description 'A great company'
    website 'http://www.testcompany.com'
    address '123 N Main st. Portland, OR 97200'
    contact_name    'Alice Wonder'
    contact_phone   '(555)555-5555'
    contact_email   'test@company.com'
    contact_title   'mentor'
  end

  factory :internship do
    company
    course
    description "You will write awesome software here!"
    ideal_intern 'Somebody who writes awesome software!'
    clearance_required true
    clearance_description "You need to have an awesome attitude!"
  end

  factory :rating do
    student
    internship
    notes 'This one looks great!'
    interest 1

    factory :low_rating do
      interest 3
    end
  end
end

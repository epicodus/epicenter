FactoryBot.define do
  factory :admin do
    sequence(:name) { |n| "Admin Brown #{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    association :current_course, factory: :course

    factory :teacher do
      teacher { true }
    end

    factory :admin_without_course do
      current_course { nil }
    end
  end

  factory :attendance_record do
    student

    factory :on_time_attendance_record do
      tardy { false }
      left_early { false }
    end

    factory :tardy_attendance_record do
      tardy { true }
    end

    factory :left_early_attendance_record do
      left_early { true }
    end
  end

  factory :bank_account do
    student
    stripe_token { {
      :object => 'bank_account',
      :country => 'US',
      :account_number => '000123456789',
      :routing_number => '110000000'
    } }

    factory :verified_bank_account do
      after(:create) do |bank_account|
        bank_account.student.stripe_customer.sources.data.each do |payment|
          if payment.object =='bank_account'
            payment.verify(amounts: [32, 45])
          end
        end
        bank_account.ensure_primary_method_exists
      end
      verified { true }
    end
  end

  factory :code_review do
    sequence(:title) { |n| "code_review #{n}" }
    course
    content { "test content" }
    date { Date.today }

    before(:create) do |code_review|
      code_review.objectives << build(:objective)
    end
  end

  factory :course do
    class_days { (Time.zone.now.to_date.beginning_of_week..(Time.zone.now.to_date + 4.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    start_time { '8:00 AM' }
    end_time { '5:00 PM' }
    association :office, factory: :philadelphia_office
    association :language, factory: :intro_language

    factory :portland_course do
      association :office, factory: :portland_office
    end

    factory :seattle_course do
      association :office, factory: :seattle_office
    end

    factory :past_course do
      class_days { ((Time.zone.now.to_date - 18.weeks).beginning_of_week..(Time.zone.now.to_date - 14.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level_3_just_finished_course do
      end_time_friday { '12:00 PM' }
      association :language, factory: :rails_language
      class_days { ((Time.zone.now.to_date - 5.weeks).beginning_of_week..(Time.zone.now.to_date - 1.week).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :future_course do
      class_days { ((Time.zone.now.to_date + 5.weeks).beginning_of_week..(Time.zone.now.to_date + 8.weeks).beginning_of_week).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :part_time_course do
      start_time { '6:00 PM' }
      end_time { '9:00 PM' }
      association :language, factory: :evening_language
    end

    factory :seattle_part_time_course do
      start_time { '6:00 PM' }
      end_time { '9:00 PM' }
      association :language, factory: :evening_language
      association :office, factory: :seattle_office
    end

    factory :portland_part_time_course do
      start_time { '6:00 PM' }
      end_time { '9:00 PM' }
      association :language, factory: :evening_language
      association :office, factory: :portland_office
    end

    factory :internship_course do
      active { true }
      association :language, factory: :internship_language
    end

    factory :portland_ruby_course do
      end_time_friday { '12:00 PM' }
      active { true }
      association :office, factory: :portland_office
      association :language, factory: :ruby_language
    end

    factory :online_course do
      association :office, factory: :online_office
      association :language, factory: :online_language
      class_days { (Time.zone.now.to_date.beginning_of_week..(Time.zone.now.to_date + 15.weeks).end_of_week).select { |day| day if day.tuesday? || day.wednesday? || day.thursday? } }
    end

    factory :level0_course do
      office { nil }
      association :language, factory: :intro_language
      class_days { (Date.parse('2017-03-13')..Date.parse('2017-04-13')).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level1_course do
      office { nil }
      association :admin, factory: :admin_without_course
      association :language, factory: :ruby_language
      class_days { (Date.parse('2017-04-17')..Date.parse('2017-05-18')).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level2_course do
      office { nil }
      association :admin, factory: :admin_without_course
      association :language, factory: :js_language
      class_days { (Date.parse('2017-05-22')..Date.parse('2017-06-22')).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level3_course do
      office { nil }
      association :admin, factory: :admin_without_course
      association :language, factory: :rails_language
      class_days { (Date.parse('2017-06-26')..Date.parse('2017-07-27')).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level4_course do
      office { nil }
      association :admin, factory: :admin_without_course
      association :language, factory: :internship_language
      class_days { (Date.parse('2017-07-31')..Date.parse('2017-09-15')).select { |day| day if !day.saturday? && !day.sunday? } }
    end
  end

  factory :cohort do
    description { '2000-01 PHL Ruby/Rails (Jan 3 - Jul 7)' }
    start_date { Time.new(2016, 1, 4).to_date }
    association :office, factory: :philadelphia_office
    association :track, factory: :track
    association :admin, factory: :admin
    before(:create) do |cohort|
      cohort.courses << build(:course, office: cohort.office, admin: cohort.admin, track: cohort.track, class_days: [cohort.start_date.beginning_of_week, cohort.start_date.beginning_of_week + 4.weeks + 3.days])
      cohort.courses.last.save
      cohort.end_date = cohort.courses.last.end_date
      cohort.admin.current_course = cohort.courses.first
    end

    factory :portland_cohort do
      association :office, factory: :portland_office
    end

    factory :cohort_internship_course do
      before(:create) do |cohort|
        course = cohort.courses.first
        course.internship_course = true
        course.save
      end
    end

    factory :part_time_cohort do
      before(:create) do |cohort|
        course = cohort.courses.first
        course.parttime = true
        course.description = 'part-time course'
        course.save
      end
    end

    factory :full_cohort do
      before(:create) do |cohort|
        cohort.courses << build(:level1_course, office: cohort.office, admin: cohort.admin, track: cohort.track, class_days: [cohort.start_date.beginning_of_week + 5.weeks, cohort.start_date.beginning_of_week + 9.weeks + 3.days])
        cohort.courses << build(:level2_course, office: cohort.office, admin: cohort.admin, track: cohort.track, class_days: [cohort.start_date.beginning_of_week + 10.weeks, cohort.start_date.beginning_of_week + 14.weeks + 3.days])
        cohort.courses << build(:level3_course, office: cohort.office, admin: cohort.admin, track: cohort.track, class_days: [cohort.start_date.beginning_of_week + 15.weeks, cohort.start_date.beginning_of_week + 19.weeks + 3.days])
        cohort.courses << build(:level4_course, office: cohort.office, admin: cohort.admin, track: cohort.track, class_days: [cohort.start_date.beginning_of_week + 20.weeks, cohort.start_date.beginning_of_week + 26.weeks + 4.days])
      end
    end
  end

  factory :credit_card do
    student
    before(:create) do |credit_card|
      card_details = { :object => 'card', :number => '4242424242424242', :exp_month => '12', :exp_year => '2020', :cvc => '123' }
      begin
        credit_card.stripe_token = StripeMock.generate_card_token(card_details)
      rescue StripeMock::UnstartedStateError # for tests not using stripe_mock
        credit_card.stripe_token = card_details
      end
    end
  end

  factory :office do
    factory :portland_office do
      name { 'Portland' }
      short_name { 'PDX' }
      time_zone { 'Pacific Time (US & Canada)' }
    end

    factory :seattle_office do
      name { 'Seattle' }
      short_name { 'SEA' }
      time_zone { 'Pacific Time (US & Canada)' }
    end

    factory :philadelphia_office do
      name { 'Philadelphia' }
      short_name { 'PHL' }
      time_zone { 'Eastern Time (US & Canada)' }
    end

    factory :online_office do
      name { 'Online' }
      short_name { 'WEB' }
      time_zone { 'Pacific Time (US & Canada)' }
    end
  end

  factory :language do
    factory :intro_language do
      name { 'Intro' }
      level { 0 }
      number_of_days { 24 }
      skip_holiday_weeks { true }
    end

    factory :evening_language do
      name { 'Evening' }
      level { 0 }
      number_of_days { 30 }
      skip_holiday_weeks { true }
      parttime { true }
    end

    factory :online_language do
      name { 'Online' }
      level { 0 }
      number_of_days { 45 }
      skip_holiday_weeks { true }
      online { true }
    end

    factory :ruby_language do
      name { 'Ruby' }
      level { 1 }
      number_of_days { 24 }
      skip_holiday_weeks { true }
    end

    factory :js_language do
      name { 'JavaScript' }
      level { 2 }
      number_of_days { 24 }
      skip_holiday_weeks { true }
    end

    factory :rails_language do
      name { 'Rails' }
      level { 3 }
      number_of_days { 24 }
      skip_holiday_weeks { true }
    end

    factory :internship_language do
      name { 'Internship' }
      level { 4 }
      number_of_days { 35 }
      skip_holiday_weeks { false }
    end
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
    stripe_token { {
      :object => 'card',
      :number => '4242424242424241',
      :exp_month => '12',
      :exp_year => '2020',
      :cvc => '123'
    } }
  end

  factory :payment do
    amount { 100 }
    category { 'upfront' }

    factory :payment_with_bank_account do
      association :student, factory: :user_with_verified_bank_account
      before(:create) do |payment|
        payment.payment_method = payment.student.payment_methods.first
      end
    end

    factory :payment_with_credit_card do
      association :student, factory: :user_with_credit_card
      before(:create) do |payment|
        payment.payment_method = payment.student.payment_methods.first
      end
    end
  end

  factory :plan do
    factory :free_intro_plan do
      short_name { 'intro' }
      name { 'Free Intro ($100 enrollment fee)' }
      close_io_description { '2018 - Free Intro ($100 enrollment fee)' }
      upfront { true }
      upfront_amount { 100_00 }
    end

    factory :upfront_payment_only_plan do
      short_name { 'fulltime-upfront' }
      name { 'Up-front Discount ($6,900 up-front)' }
      close_io_description { '2018 - Up-front Discount ($6,900 up-front)' }
      upfront { true }
      upfront_amount { 6900_00 }
    end

    factory :standard_plan do
      short_name { 'fulltime-standard' }
      name { 'Pay As You Go (4 payments of $2,125)' }
      close_io_description { '2018 - Pay As You Go (4 payments of $2,125)' }
      standard { true }
      upfront_amount { 100_00 }
      first_day_amount { 2100_00 }
    end

    factory :loan_plan do
      short_name { 'fulltime-loan' }
      name { 'Loan ($100 enrollment fee)' }
      close_io_description { '2018 - Loan ($100 enrollment fee)' }
      loan { true }
      upfront_amount { 100_00 }
    end

    factory :parttime_plan do
      short_name { 'parttime' }
      name { 'Legacy - Evening intro class ($600)' }
      close_io_description { '2018 - Evening intro class ($600)' }
      parttime { true }
      upfront_amount { 600_00 }
    end
  end

  factory :objective do
    content { 'Continue meeting all the objectives from previous code reviews' }
  end

  factory :review do
    note { 'Great job!' }
    sequence(:student_signature) { |n| "Example Student #{n}" }
    submission

    factory :passing_review do
      after(:build) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryBot.create(:passing_grade, review: review, objective: objective)
        end
      end
    end

    factory :failing_review do
      after(:build) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryBot.create(:failing_grade, review: review, objective: objective)
        end
      end
    end

    factory :in_between_review do
      after(:build) do |review|
        review.submission.code_review.objectives.each do |objective|
          FactoryBot.create(:in_between_grade, review: review, objective: objective)
        end
      end
    end
  end

  factory :score do
    sequence(:description) { |n| "Meets expectations #{n} of the time" }

    factory :failing_score do
      value { 1 }
    end

    factory :passing_score do
      value { 3 }
    end

    factory :in_between_score do
      value { 2 }
    end
  end

  factory :signature do
    student

    factory :completed_code_of_conduct do
      type { CodeOfConduct }
      is_complete { true }
    end

    factory :completed_refund_policy do
      type { RefundPolicy }
      is_complete { true }
    end

    factory :completed_complaint_disclosure do
      type { ComplaintDisclosure }
      is_complete { true }
    end

    factory :completed_enrollment_agreement do
      type { EnrollmentAgreement }
      is_complete { true }
    end

    factory :completed_student_internship_agreement do
      type { StudentInternshipAgreement }
      is_complete { true }
      signature_id { 'test' }
    end
  end

  factory :student do
    course
    association :plan, factory: :free_intro_plan
    association :office, factory: :philadelphia_office
    sequence(:name) { |n| "Example Brown #{n}" }
    sequence(:email) { |n| "student#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }

    factory :seattle_student do
      association :course, factory: :seattle_course
      association :office, factory: :seattle_office
    end

    factory :portland_student_with_all_documents_signed do
      demographics { true }
      association :course, factory: :portland_course
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
      end
    end

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

    factory :part_time_student_with_payment_method do
      association :course, factory: :part_time_course
      after(:create) do |student|
        create(:credit_card, student: student)
      end
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

      factory :user_with_upfront_payment do
        after(:create) do |student|
          student.make_upfront_payment
        end
      end
    end

    factory :user_waiting_on_demographics do
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
      end
    end

    factory :user_with_all_documents_signed do
      demographics { true }
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
      end
    end

    factory :user_with_all_documents_signed_and_verified_bank_account do
      demographics { true }
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
        create(:verified_bank_account, student: student)
      end
    end

    factory :user_with_all_documents_signed_and_unverified_bank_account do
      demographics { true }
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
        create(:bank_account, student: student)
      end
    end

    factory :user_with_all_documents_signed_and_credit_card do
      demographics { true }
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
        create(:credit_card, student: student)
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

    factory :student_in_full_cohort do
      before(:create) do |student|
        full_cohort = create(:full_cohort)
        student.courses = []
        full_cohort.courses.each { |course| student.courses << course }
      end
    end
  end

  factory :submission do
    link { 'http://github.com' }
    code_review
    student
  end

  factory :company do
    sequence(:name) { |n| "Company employee #{n}" }
    sequence(:email) { |n| "employee#{n}@company.com" }
    password { "password" }
    password_confirmation { "password" }
  end

  factory :internship do
    company
    sequence(:name) { |n| "#{n} labs" }
    website { 'http://www.testcompany.com' }
    address { '123 N Main st. Portland, OR 97200' }
    description { "You will write awesome software here!" }
    ideal_intern { 'Somebody who writes awesome software!' }
    clearance_required { true }
    clearance_description { "You need to have an awesome attitude!" }
    number_of_students { 2 }
    before(:create) do |internship|
      internship.courses << create(:internship_course)
      internship.tracks << create(:track)
    end
  end

  factory :rating do
    student
    internship
    number { 1 }
  end

  factory :track do
    description { 'Ruby/Rails' }
    before(:create) do |track|
      track.languages << build(:intro_language)
      track.languages << build(:ruby_language)
      track.languages << build(:js_language)
      track.languages << build(:rails_language)
      track.languages << build(:internship_language)
    end

    factory :part_time_track do
      description { 'Part-time' }
      before(:create) do |track|
        track.languages = []
        track.languages << build(:evening_language)
      end
    end

    factory :online_track do
      description { 'Online' }
      before(:create) do |track|
        track.languages = []
        track.languages << build(:online_language)
      end
    end
  end

  factory :interview_assignment do
    student
    internship
    course
  end

  factory :internship_assignment do
    student
    internship
    course
  end

  factory :demographic_info do
    address { 'test address' }
    city { 'portland' }
    state { 'OR' }
    zip { '90001' }
    country { 'US' }
    birth_date { '2000-01-01' }
    disability { 'No' }
    veteran { 'No' }
    education { 'GED' }
    cs_degree { 'No' }
    shirt { 'S' }
  end
end

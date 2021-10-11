FactoryBot.define do
  factory :admin do
    sequence(:name) { |n| "Admin Brown #{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }

    factory :teacher do
      teacher { true }
    end

    trait :with_course do
      before(:create) do |admin|
        create_list(:course, 1, admin: admin)
        admin.current_course = admin.courses.first
      end
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
    visible_date { Time.zone.now.beginning_of_day + 8.hours }
    due_date { Time.zone.now.beginning_of_day + 17.hours }

    before(:create) do |code_review|
      code_review.objectives << build(:objective) unless code_review.journal?
    end

    factory :journal do
      sequence(:title) { |n| "journal #{n}" }
      journal { true }
      visible_date { nil }
      due_date { nil }
    end
  end

  factory :class_time do
    wday { 1 }
    start_time { '8:00' }
    end_time { '17:00' }

    factory :class_time_evening do
      wday { 1 }
      start_time { '18:00' }
      end_time { '21:00' }
    end

    factory :class_time_sunday do
      wday { 0 }
      start_time { '9:00' }
      end_time { '17:00' }
    end
  end

  factory :course do
    sequence(:description) { |n| "example course #{n}" }
    class_days { (Time.zone.now.to_date.beginning_of_week..(Time.zone.now.to_date + 4.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    association :language, factory: :intro_language
    association :office, factory: :philadelphia_office
    track
    admin
    cohort { association :cohort, office: office, track: track, admin: admin }

    factory :course_with_class_times do
      association :office, factory: :portland_office
      before(:create) do |course|
        5.times { |i| course.class_times << build(:class_time, wday: i+1) }
      end
    end

    factory :pt_course_with_class_times do
      parttime { true }
      class_days { (Time.zone.now.to_date.beginning_of_week..(Time.zone.now.to_date + 5.weeks).end_of_week-4.days).select { |day| day if day.sunday? || day.monday? || day.tuesday? || day.wednesday? } }
      association :office, factory: :portland_office
      association :language, factory: :intro_part_time_c_react_language
      before(:create) do |course|
        course.class_times << build(:class_time_sunday)
        3.times { |i| course.class_times << build(:class_time_evening, wday: i+1) }
      end
    end

    factory :portland_course do
      association :office, factory: :portland_office
    end

    factory :seattle_course do
      association :office, factory: :seattle_office
    end

    factory :past_course do
      class_days { ((Time.zone.now.to_date - 18.weeks).beginning_of_week..(Time.zone.now.to_date - 14.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :midway_course do
      class_days { ((Time.zone.now.to_date - 2.weeks).beginning_of_week..(Time.zone.now.to_date + 3.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :level_3_just_finished_course do
      association :language, factory: :rails_language
      class_days { ((Time.zone.now.to_date - 5.weeks).beginning_of_week..(Time.zone.now.to_date - 1.week).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :future_course do
      class_days { ((Time.zone.now.to_date + 5.weeks).beginning_of_week..(Time.zone.now.to_date + 8.weeks).beginning_of_week).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :part_time_course do
      parttime { true }
      association :language, factory: :intro_part_time_c_react_language
      association :track, factory: :part_time_track
    end

    factory :intro_part_time_c_react_course do
      association :language, factory: :intro_part_time_c_react_language
    end

    factory :js_part_time_c_react_course do
      association :language, factory: :js_part_time_c_react_language
    end

    factory :c_part_time_c_react_course do
      association :language, factory: :c_part_time_c_react_language
    end

    factory :react_part_time_c_react_course do
      association :language, factory: :react_part_time_c_react_language
    end

    factory :seattle_part_time_course do
      association :language, factory: :intro_part_time_c_react_language
      association :office, factory: :seattle_office
    end

    factory :portland_part_time_course do
      association :language, factory: :intro_part_time_c_react_language
      association :office, factory: :portland_office
    end

    factory :internship_course do
      description { 'internship course' }
      internship_course { true }
      active { true }
      association :language, factory: :internship_language
    end

    factory :midway_internship_course do
      description { 'internship course' }
      active { true }
      association :language, factory: :internship_language
      class_days { ((Time.zone.now.to_date - 2.weeks).beginning_of_week..(Time.zone.now.to_date + 3.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
    end

    factory :past_internship_course do
      description { 'internship course' }
      active { true }
      class_days { ((Time.zone.now.to_date - 18.weeks).beginning_of_week..(Time.zone.now.to_date - 14.weeks).end_of_week - 2.days).select { |day| day if !day.saturday? && !day.sunday? } }
      association :language, factory: :internship_language
    end

    factory :portland_ruby_course do
      active { true }
      association :office, factory: :portland_office
      association :language, factory: :ruby_language
    end

    factory :level0_course do
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
      description { "internship course" }
      office { nil }
      internship_course { true }
      association :admin, factory: :admin_without_course
      association :language, factory: :internship_language
      class_days { (Date.parse('2017-07-31')..Date.parse('2017-09-15')).select { |day| day if !day.saturday? && !day.sunday? } }
    end
  end

  factory :cohort do
    start_date { Time.zone.now.to_date.beginning_of_week }
    office
    track
    admin
    after(:create) do |cohort|
      if cohort.courses.any?
        cohort.update(end_date: cohort.courses.last.end_date)
        cohort.update(description: "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} #{cohort.track.description}")
      end
    end

    factory :ft_cohort do
      before(:create) do |cohort|
        cohort.courses << build(:level0_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages.first, class_days: [cohort.start_date.beginning_of_week, cohort.start_date.beginning_of_week + 4.weeks + 3.days])
        cohort.courses << build(:level4_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages.last, class_days: [cohort.start_date.beginning_of_week + 5.weeks, cohort.start_date.beginning_of_week + 8.weeks + 3.days])
      end
    end

    factory :ft_full_cohort do
      before(:create) do |cohort|
        cohort.courses << build(:level0_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[0], class_days: [cohort.start_date.beginning_of_week, cohort.start_date.beginning_of_week + 4.weeks + 3.days])
        cohort.courses << build(:level1_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[1], class_days: [cohort.start_date.beginning_of_week + 5.weeks, cohort.start_date.beginning_of_week + 9.weeks + 3.days])
        cohort.courses << build(:level2_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[2], class_days: [cohort.start_date.beginning_of_week + 10.weeks, cohort.start_date.beginning_of_week + 14.weeks + 3.days])
        cohort.courses << build(:level3_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[3], class_days: [cohort.start_date.beginning_of_week + 15.weeks, cohort.start_date.beginning_of_week + 19.weeks + 3.days])
        cohort.courses << build(:level4_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[4], class_days: [cohort.start_date.beginning_of_week + 20.weeks, cohort.start_date.beginning_of_week + 26.weeks + 4.days])
      end
    end

    factory :pt_intro_cohort do
      association :track, factory: :part_time_track
      before(:create) do |cohort|
        cohort.courses << build(:part_time_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages.first, class_days: [cohort.start_date.beginning_of_week, cohort.start_date.beginning_of_week + 14.weeks + 2.days])
      end
    end

    factory :pt_c_react_cohort do
      description { '2021-01-04 to 2021-10-10 PDX Part-Time C/React' }
      association :track, factory: :part_time_c_react_track
      before(:create) do |cohort|
        cohort.courses << build(:intro_part_time_c_react_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[0], class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
        cohort.courses << build(:js_part_time_c_react_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[1], class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
        cohort.courses << build(:c_part_time_c_react_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[2], class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
        cohort.courses << build(:react_part_time_c_react_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[3], class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
        cohort.courses << build(:internship_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages[4], class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
      end
    end

    factory :pt_js_react_cohort do
      description { '2021-01-04 to 2021-10-10 PDX Part-Time JS/React' }
      association :track, factory: :part_time_js_react_track
      before(:create) do |cohort|
        cohort.courses << build(:intro_part_time_c_react_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages.first, class_days: [cohort.start_date, cohort.start_date + 1.days, cohort.start_date + 2.days, cohort.start_date + 6.days, cohort.start_date + 6.weeks - 1.day])
      end
    end

    factory :fidgetech_cohort do
      description { 'Fidgetech' }
      before(:create) do |cohort|
        cohort.courses << build(:level0_course, cohort: cohort, office: cohort.office, admin: cohort.admin, track: cohort.track, language: cohort.track.languages.first, class_days: [cohort.start_date.beginning_of_week, cohort.start_date.beginning_of_week + 4.weeks + 3.days], description: 'Fidgetech')
      end
      after(:create) do |cohort|
        cohort.update(description: 'Fidgetech')
      end
    end
  end

  factory :credit_card do
    student
    before(:create) do |credit_card|
      card_details = { :object => 'card', :number => '4242424242424242', :exp_month => '12', :exp_year => '2025', :cvc => '123' }
      begin
        credit_card.stripe_token = StripeMock.generate_card_token(card_details)
      rescue StripeMock::UnstartedStateError # for tests not using stripe_mock
        credit_card.stripe_token = card_details
      end
    end
  end

  factory :office do
    name { 'Portland' }
    short_name { 'PDX' }
    time_zone { 'Pacific Time (US & Canada)' }

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
    end

    factory :ruby_language do
      name { 'Ruby' }
      level { 1 }
    end

    factory :js_language do
      name { 'JavaScript' }
      level { 2 }
    end

    factory :rails_language do
      name { 'Rails' }
      level { 3 }
    end

    factory :internship_language do
      name { 'Internship' }
      level { 4 }
    end

    factory :intro_part_time_c_react_language do
      name { 'Intro (part-time track)' }
      level { 0 }
    end

    factory :js_part_time_c_react_language do
      name { 'JavaScript (part-time track)' }
      level { 1 }
    end

    factory :c_part_time_c_react_language do
      name { 'Intro (part-time track)' }
      level { 2 }
    end

    factory :react_part_time_c_react_language do
      name { 'React (part-time track)' }
      level { 3 }
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
      :exp_year => '2025',
      :cvc => '123'
    } }
  end

  factory :payment do
    amount { 100 }
    category { 'upfront' }
    after(:build) do |payment|
      payment.cohort = payment.student.latest_cohort
    end

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

    factory :refund do
      amount { 0 }
      refund_amount { 100 }
      category { 'refund' }
      refund_date { Time.zone.now.to_date }
    end

    factory :offline_refund do
      amount { 0 }
      refund_amount { 100 }
      category { 'refund' }
      offline { true }
      refund_date { Time.zone.now.to_date }
      after(:build) do |payment|
        payment.cohort = nil
        payment.linked_payment = build(:payment, student: payment.student)
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
      student_portion { 100_00 }
    end

    factory :upfront_plan do
      short_name { 'fulltime-upfront' }
      name { 'Up-Front Discount ($7,800 up-front)' }
      close_io_description { '2018 - Up-Front Discount ($7,800 up-front)' }
      upfront { true }
      upfront_amount { 7800_00 }
      student_portion { 7800_00 }
    end

    factory :standard_plan_legacy do
      short_name { 'fulltime-standard' }
      name { 'Pay As You Go (4 payments of $2,125)' }
      close_io_description { '2018 - Pay As You Go (4 payments of $2,125)' }
      standard { true }
      upfront_amount { 100_00 }
      student_portion { 8500_00 }
    end

    factory :standard_plan do
      short_name { 'standard' }
      name { 'Standard Tuition ($100 then $8800)' }
      close_io_description { '2018 - Standard Plan ($100 then $8800)' }
      standard { true }
      upfront_amount { 100_00 }
      student_portion { 8800_00 }
    end

    factory :loan_plan do
      short_name { 'fulltime-loan' }
      name { 'Loan ($100 enrollment fee)' }
      close_io_description { '2018 - Loan ($100 enrollment fee)' }
      loan { true }
      upfront_amount { 100_00 }
      student_portion { 100_00 }
    end

    factory :isa_plan do
      short_name { 'isa' }
      name { 'Income Share Agreement' }
      close_io_description { 'Income Share Agreement ($11,700)' }
      isa { true }
      upfront_amount { 0 }
      student_portion { 0 }
    end

    factory :parttime_plan do
      short_name { 'parttime-intro' }
      name { 'Evening intro class ($100)' }
      close_io_description { 'Evening intro class ($100)' }
      parttime { true }
      upfront_amount { 100_00 }
      student_portion { 100_00 }
    end

    factory :special_plan do
      short_name { 'special-other' }
      name { 'Special (other special arrangement)' }
      close_io_description { 'Other - Special arrangement' }
      upfront { true }
      upfront_amount { 0 }
      student_portion { 0 }
    end

    factory :grant_plan do
      short_name { 'special-grant' }
      name { 'Special (3rd-party grant)' }
      close_io_description { '3rd-party grant' }
      upfront_amount { 100_00 }
      student_portion { 100_00 }
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
    sequence(:name) { |n| "Example Brown #{n}" }
    sequence(:email) { |n| "student#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    after(:create) do |student|
      student.parttime_cohort = student.calculate_parttime_cohort
      student.cohort = student.calculate_current_cohort
      student.starting_cohort = student.calculate_starting_cohort
      student.save if student.changed?
    end

    trait :with_course do
      course
    end

    trait :with_ft_cohort do
      association :cohort, factory: :ft_cohort
      before(:create) do |student|
        student.courses << student.cohort.courses
      end
    end

    trait :with_pt_c_react_cohort do
      association :cohort, factory: :part_time_c_react_cohort
      before(:create) do |student|
        student.courses << student.cohort.courses
      end
    end

    trait :with_pt_intro_cohort do
      association :parttime_cohort, factory: :pt_intro_cohort
      before(:create) do |student|
        student.courses << student.parttime_cohort.courses
      end
    end

    trait :with_fidgetech_cohort do
      association :parttime_cohort, factory: :fidgetech_cohort
      before(:create) do |student|
        student.courses << student.parttime_cohort.courses
      end
    end

    factory :pt_intro_student_with_cohort do
      association :plan, factory: :parttime_plan
      with_pt_intro_cohort
    end

    factory :fidgetech_student_with_cohort do
      association :plan, factory: :parttime_plan
      with_fidgetech_cohort
    end

    factory :pt_c_react_student_with_cohort do
      association :plan, factory: :standard_plan
      with_pt_c_react_cohort
    end

    trait :with_plan do
      association :plan, factory: :upfront_plan
    end

    trait :with_credit_card do
      after(:create) do |student|
        create(:credit_card, student: student)
      end
    end

    trait :with_invalid_credit_card do
      after(:create) do |student|
        create(:invalid_credit_card, student: student)
      end
    end

    trait :with_unverified_bank_account do
      after(:create) do |student|
        create(:bank_account, student: student)
      end
    end

    trait :with_verified_bank_account do
      after(:create) do |student|
        create(:verified_bank_account, student: student)
      end
    end

    trait :with_upfront_payment do
      with_verified_bank_account
      association :plan, factory: :upfront_plan
      after(:create) do |student|
        student.make_upfront_payment
      end
    end

    trait :with_all_documents_signed do
      demographics { true }
      after(:create) do |student|
        create(:completed_code_of_conduct, student: student)
        create(:completed_refund_policy, student: student)
        create(:completed_enrollment_agreement, student: student)
      end
    end

    # BELOW PREVIOUSLY HAD ASSOCIATED COURSES AND PLAN ASSOCIATED

    factory :seattle_student do
      association :course, factory: :seattle_course
    end

    factory :portland_student do
      association :course, factory: :portland_course
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
    link { 'http://github.com' }
    code_review
    student

    factory :journal_submission do
      link {}
      sequence(:journal) { |n| "Reflection content #{n}" }
    end
  end

  factory :daily_submission do
    link { 'http://github.com' }
    date { Time.zone.now.to_date }
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
    hiring { 'maybe' }
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
      description { 'Part-Time Intro to Programming' }
      before(:create) do |track|
        track.languages = []
        track.languages << build(:intro_part_time_c_react_language)
      end
    end

    factory :part_time_c_react_track do
      description { 'Part-Time C#/React' }
      before(:create) do |track|
        track.languages = []
        track.languages << build(:intro_part_time_c_react_language)
        track.languages << build(:js_part_time_c_react_language)
        track.languages << build(:c_part_time_c_react_language)
        track.languages << build(:react_part_time_c_react_language)
        track.languages << build(:internship_language)
      end
    end

    factory :part_time_js_react_track do
      description { 'Part-Time JS/React' }
      before(:create) do |track|
        track.languages = []
        track.languages << build(:intro_part_time_c_react_language)
        track.languages << build(:js_part_time_c_react_language)
        track.languages << build(:react_part_time_c_react_language)
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
    after_graduation { 'I intend to remain with my current employer upon graduation.' }
  end

  factory :cost_adjustment do
    amount { 100_00 }
    reason { 'test adjustment' }
  end

  factory :peer_evaluation do
    association :evaluator, factory: :student
    association :evaluatee, factory: :student
  end

  factory :peer_question do
    content { 'test question' }
    category { 'technical' }

    factory :peer_question_feedback do
      category { 'feedback' }
    end
  end

  factory :peer_response do
    peer_evaluation
    peer_question
    response { 'All of the time' }

    factory :peer_response_feedback do
      association :peer_question, factory: :peer_question_feedback
      response { 'foo' }
    end
  end

  factory :pair_feedback do
    student
    association :pair, factory: :student
    q1_response { 1 }
    q2_response { 2 }
    q3_response { 3 }
  end
end

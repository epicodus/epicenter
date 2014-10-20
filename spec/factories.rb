FactoryGirl.define do
  factory :bank_account do
    user

    after(:build) do |bank_account|
      balanced_bank_account = create_balanced_bank_account
      bank_account.account_uri = balanced_bank_account.href
    end

    factory :verified_bank_account do
      after(:create) do |verified_bank_account|
        verification = Verification.new(bank_account: verified_bank_account,
                                        first_deposit: 1,
                                        second_deposit: 1)
        verification.confirm
      end
      verified true
    end
  end

  factory :payment do
    association :bank_account, factory: :verified_bank_account
    amount 1
  end

  factory :plan do
    name "summer 2014"

    factory :recurring_plan_with_upfront_payment do
      upfront_amount 200_00
      recurring_amount 600_00
    end

    factory :upfront_payment_only_plan do
      upfront_amount 3400_00
      recurring_amount 0
    end

    factory :recurring_plan_with_no_upfront_payment do
      upfront_amount 0
      recurring_amount 625_00
    end
  end

  factory :user do
    cohort
    association :plan, factory: :recurring_plan_with_upfront_payment
    sequence(:name) { |n| "Example Brown #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password "password"
    password_confirmation "password"

    factory :user_with_unverified_bank_account do
      association :bank_account
    end

    factory :user_with_verified_bank_account do
      association :bank_account, factory: :verified_bank_account

      factory :user_with_recurring_active do
        recurring_active true
        after(:create) do |user|
          create(:payment, bank_account: user.bank_account)
        end
      end

      factory :user_with_recurring_not_due do
        recurring_active true
        after(:create) do |user|
          create(:payment, bank_account: user.bank_account, created_at: 2.weeks.ago)
        end
      end

      factory :user_with_recurring_due do
        recurring_active true
        after(:create) do |user|
          create(:payment, bank_account: user.bank_account, created_at: 1.month.ago)
        end
      end

      factory :user_with_upfront_payment do
        after(:create) do |user|
          user.make_upfront_payment
        end
      end

    end
  end

  factory :attendance_record do
    user
  end

  factory :cohort do
    description 'Current cohort'
    start_date Date.today.beginning_of_week
    end_date (Date.today + 14.weeks).end_of_week - 2.days

    factory :past_cohort do
      start_date 125.days.ago.beginning_of_week
      end_date 20.days.ago.end_of_week - 2.days
    end
  end
end

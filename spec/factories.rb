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

      factory :new_recurring_bank_account do
        after(:create) do |bank_account|
          bank_account.start_recurring_payments
        end

        factory :recurring_bank_account_not_due do
          after(:create) do |bank_account|
            bank_account.payments.first.update(created_at: 2.weeks.ago)
          end
        end

        factory :recurring_bank_account_due do
          after(:create) do |bank_account|
            bank_account.payments.first.update(created_at: 1.month.ago)
          end
        end
      end
    end
  end

  factory :payment do
    association :bank_account, factory: :verified_bank_account
    amount 1
  end

  factory :plan do
    name "summer 2014, recurring"
    recurring_amount 600_00

    factory :plan_with_upfront_payment do
      upfront_amount 200_00
    end
  end

  factory :user do
    association :plan, factory: :plan_with_upfront_payment
    name "Jane Doe"
    sequence(:email) { |n| "user#{n}@example.com" }
    password "password"
    password_confirmation "password"

    factory :user_with_unverified_bank_account do
      association :bank_account
    end

    factory :user_with_verified_bank_account do
      association :bank_account, factory: :verified_bank_account

      factory :user_with_recurring_active do
        after(:create) do |user|
          user.bank_account.start_recurring_payments
        end
      end

      factory :user_with_a_payment do
        after(:create) do |user|
          user.bank_account.make_upfront_payment
        end
      end

    end
  end

  factory :attendance_record do
    user
  end
end

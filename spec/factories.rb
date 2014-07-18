FactoryGirl.define do
  factory :subscription do
    after(:build) do |subscription|
      bank_account = create_bank_account
      subscription.account_uri = bank_account.href
    end

    factory :verified_subscription do
      after(:create) do |verified_subscription|
        verification = Verification.new(subscription: verified_subscription,
                                        first_deposit: 1,
                                        second_deposit: 1)
        verification.confirm
      end
      verified true
    end
  end

  factory :user do
    name "Jane Doe"
    sequence(:email) { |n| "user#{n}@example.com" }
    password "password"
    password_confirmation "password"

    factory :user_with_unverified_subscription do
      association :subscription
    end

    factory :user_with_verified_subscription do
      association :subscription, factory: :verified_subscription
    end
  end
end

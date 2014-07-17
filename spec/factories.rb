FactoryGirl.define do
  factory :subscription do
    before(:create) do |subscription|
      bank_account = create_bank_account
      subscription.account_uri = bank_account.href
    end

    factory :verified_subscription do
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

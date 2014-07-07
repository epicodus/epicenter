FactoryGirl.define do
  factory :subscription do
    before(:create) do |subscription|
      bank_account = Balanced::BankAccount.new(
        :account_number => '9900000002',
        :account_type => 'checking',
        :name => 'Johann Bernoulli',
        :routing_number => '021000021'
      ).save
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

    factory :user_with_subscription do
      association :subscription, factory: :verified_subscription
    end
  end
end

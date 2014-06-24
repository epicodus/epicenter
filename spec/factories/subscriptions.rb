FactoryGirl.define do
  factory :subscription do
    Balanced.configure('ak-test-2q80HU8DISm2atgm0iRKRVIePzDb34qYp')
    bank_account = Balanced::BankAccount.new(
      :account_number => '9900000002',
      :account_type => 'checking',
      :name => 'Johann Bernoulli',
      :routing_number => '021000021'
    ).save
    account_uri(bank_account.href)
    factory :verified_subscription do
      verified true
    end
  end
end

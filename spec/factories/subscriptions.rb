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
  end
end

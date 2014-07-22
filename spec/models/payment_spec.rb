require 'rails_helper'

describe Payment do

  it { should belong_to :bank_account }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :bank_account_id }

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      bank_account = FactoryGirl.create :verified_bank_account
      bank_account.payments.create(amount: 100)
      expect(bank_account.payments.first.payment_uri).to_not be_nil
    end
  end
end

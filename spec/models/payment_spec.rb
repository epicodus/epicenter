require 'rails_helper'

describe Payment do

  it { should belong_to :user }
  it { should belong_to :payment_method }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :user_id }

  describe "make a payment" do
    it "makes a successful payment", :vcr do
      user = FactoryGirl.create :user_with_unverified_bank_account
      user.payments.create(amount: 100)
      expect(user.payments.first.payment_uri).to_not be_nil
    end
  end
end

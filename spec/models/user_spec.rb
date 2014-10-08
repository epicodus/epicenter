require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should validate_presence_of :plan_id }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should belong_to :plan }

  describe "#upfront_payment_due?", :vcr do
    let(:user) { FactoryGirl.create :user_with_verified_bank_account }

    it "is true if user has upfront payment and no payments have been made" do
      expect(user.upfront_payment_due?).to be true
    end

    it "is false if user has no upfront payment" do
      user.plan.upfront_amount = 0
      expect(user.upfront_payment_due?).to be false
    end

    it "is false if user has made any payments" do
      user = FactoryGirl.create :user_with_a_payment
      expect(user.upfront_payment_due?).to be false
    end
  end
end


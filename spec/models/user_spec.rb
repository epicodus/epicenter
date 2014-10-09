require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should validate_presence_of :plan_id }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should belong_to :plan }
  it { should have_many :attendance_records }

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

  describe "#make_upfront_payment", :vcr do
    it "makes a payment for the upfront amount of the user's plan" do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      user.make_upfront_payment
      expect(user.payments.first.amount).to eq user.plan.upfront_amount
    end
  end

  describe '#signed_in_today?' do
    let(:user) { FactoryGirl.create(:user) }

    it 'is false if the user has not signed in today' do
      expect(user.signed_in_today?).to eq false
    end

    it 'is true if the user has already signed in today' do
      attendance_record = FactoryGirl.create(:attendance_record, user: user)
      expect(user.signed_in_today?).to eq true
    end
  end
end

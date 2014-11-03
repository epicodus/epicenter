require 'rails_helper'

describe CreditCard do
  it { should belong_to :user }
  it { should have_many :payments }
  it { should validate_presence_of :credit_card_uri }
  it { should validate_presence_of :user_id }

  describe "create create card", :vcr do
    let(:credit_card) { FactoryGirl.create :credit_card }

    it "gets last four digits before_create" do
      credit_card = FactoryGirl.create(:credit_card)
      expect(credit_card.last_four_string).to eq "xxxxxxxxxxxx1111"
    end

    it "is made the primary payment method if user does not have one" do
      credit_card = FactoryGirl.create(:credit_card)
      expect(credit_card.user.primary_payment_method).to eq credit_card
    end
  end

  describe "#fetch_balanced_account" do
    it "returns the balanced credit card object", :vcr do
      credit_card = FactoryGirl.create :credit_card
      expect(credit_card.fetch_balanced_account.href).to eq credit_card.credit_card_uri
    end
  end

  describe "#calculate_fee" do
    it "returns the credit card fees for the amount given", :vcr do
      credit_card = FactoryGirl.create :credit_card
      expect(credit_card.calculate_fee(600_00)).to eq 18_21
    end
  end
end

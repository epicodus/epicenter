require 'rails_helper'

describe CreditCard do
  it { should belong_to :student }
  it { should have_many :payments }
  it { should validate_presence_of :credit_card_uri }
  it { should validate_presence_of :student_id }

  describe "create create card", :vcr do
    let(:credit_card) { FactoryGirl.create :credit_card }

    it "gets last four digits before_create" do
      credit_card = FactoryGirl.create(:credit_card)
      expect(credit_card.last_four_string).to eq "xxxxxxxxxxxx1111"
    end

    it "is made the primary payment method if student does not have one" do
      credit_card = FactoryGirl.create(:credit_card)
      expect(credit_card.student.primary_payment_method).to eq credit_card
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

  describe "#verified?" do
    it "returns true", :vcr do
      credit_card = FactoryGirl.create :credit_card
      expect(credit_card.verified?).to eq true
    end
  end
end

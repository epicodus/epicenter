require 'rails_helper'

describe BankAccount do
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :user_id }
  it { should belong_to :user }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "creates a verification before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.verification_uri).to_not be_nil
    end
  end

  describe "#fetch_balanced_account" do
    it "returns the balanced bank account object", :vcr do
      bank_account = FactoryGirl.create :verified_bank_account
      expect(bank_account.fetch_balanced_account.href).to eq bank_account.account_uri
    end
  end

  describe "#calculate_fee" do
    it "returns zero", :vcr do
      bank_account = FactoryGirl.create :verified_bank_account
      expect(bank_account.calculate_fee(600_00)).to eq 0
    end
  end
end


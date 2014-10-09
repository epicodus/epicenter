require 'rails_helper'

describe BankAccount do
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :user_id }
  it { should belong_to :user }
  it { should have_one :plan }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "creates a verification before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.verification_uri).to_not be_nil
    end
  end
end

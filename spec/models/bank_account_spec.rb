describe BankAccount do
  it { should validate_presence_of :student_id }
  it { should belong_to :student }
  it { should have_many :payments }

  describe "verify Stripe account", :vcr, js: true do
    let(:student) { FactoryBot.create :user_with_verified_bank_account }

    it "verifies a Stripe account before_update", :vcr, js: true do
      bank_account = FactoryBot.create(:bank_account)
      bank_account.update(first_deposit: 32, second_deposit: 45)
      stripe_account = bank_account.student.stripe_customer.bank_accounts.retrieve(bank_account.stripe_id)
      expect(stripe_account.status).to eq "verified"
    end
  end

  describe "#verify_account", :vcr, js: true do
    it "sets the student's bank_account verified status to true", :vcr, js: true do
      student = FactoryBot.create(:user_with_verified_bank_account)
      expect(student.bank_accounts.first.verified).to be true
    end

    it "sets the confirmed bank account as the primary payment method if student does not have one", :vcr, js: true do
      student = FactoryBot.create(:user_with_verified_bank_account)
      expect(student.primary_payment_method).to be_an_instance_of(BankAccount)
    end
  end

  describe "#starting_status" do
    it "returns 'pending'", :vcr, js: true do
      bank_account = FactoryBot.create :bank_account
      expect(bank_account.starting_status).to eq 'pending'
    end
  end

  describe "#calculate_fee" do
    it "returns zero", :vcr, js: true do
      bank_account = FactoryBot.create :verified_bank_account
      expect(bank_account.calculate_fee(600_00)).to eq 0
    end
  end

  # TEST WON'T PASS: "Public tokens expire 30 minutes after creation at which point they can no longer be exchanged"
  # describe ".exchange_plaid_token", :vcr do
  #   it "successfully obtains bank account token" do
  #     test_public_token = ENV['PLAID_TEST_PUBLIC_TOKEN']
  #     test_account_id = ENV['PLAID_TEST_ACCOUNT_ID']
  #     expect(BankAccount.exchange_plaid_token(test_public_token, test_account_id)).to eq ENV['PLAID_TEST_BANK_ACCOUNT_TOKEN']
  #   end
  # end
end

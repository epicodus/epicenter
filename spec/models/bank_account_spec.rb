describe BankAccount do
  it { should validate_presence_of :student_id }
  it { should belong_to :student }
  it { should have_many :payments }

  describe "create bank account", :vcr do
    let(:bank_account) { FactoryGirl.create :bank_account }

    it "creates a Stripe bank account" do
      account = FactoryGirl.create(:bank_account)
      stripe_account = account.student.stripe_customer.sources.data.first
      expect(stripe_account).to be_an_instance_of(Stripe::BankAccount)
    end

    it "gets last four digits before_create" do
      bank_account = FactoryGirl.create(:bank_account)
      expect(bank_account.last_four_string).to eq "6789"
    end
  end

  describe "verify Stripe account", :vcr do
    let(:student) { FactoryGirl.create :user_with_verified_bank_account }

    it "verifies a Stripe account after_update" do
      bank_account = FactoryGirl.create(:bank_account)
      bank_account.update(first_deposit: 32, second_deposit: 45)
      stripe_account = bank_account.student.stripe_customer.sources.data.first
      expect(stripe_account.status).to eq "verified"
    end
  end

  describe "#create_verification" do
    it "sets the student's bank_account verified status to true", :vcr do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      expect(student.bank_accounts.first.verified).to be true
    end

    it "sets the confirmed bank account as the primary payment method if student does not have one", :vcr do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      expect(student.primary_payment_method).to be_an_instance_of(BankAccount)
    end
  end

  describe "#starting_status" do
    it "returns 'pending'", :vcr do
      bank_account = FactoryGirl.create :bank_account
      expect(bank_account.starting_status).to eq 'pending'
    end
  end

  describe "#calculate_fee" do
    it "returns zero", :vcr do
      bank_account = FactoryGirl.create :verified_bank_account
      expect(bank_account.calculate_fee(600_00)).to eq 0
    end
  end
end

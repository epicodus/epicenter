describe PaymentMethod do
  it { should validate_presence_of :student_id }
  it { should belong_to :student }
  it { should have_many :payments }

  describe "create Stripe account", :vcr do
    context "with a valid number" do
      let(:credit_card) { FactoryBot.create :credit_card }
      let(:bank_account) { FactoryBot.create :bank_account }

      it "creates a Stripe card for a Stripe customer", :stripe_mock do
        credit_card = FactoryBot.create(:credit_card)
        stripe_card = credit_card.student.stripe_customer.sources.first
        expect(stripe_card).to be_an_instance_of(Stripe::Card)
      end

      it "creates a Stripe bank account for a Stripe customer", :vcr, js: true do
        account = FactoryBot.create(:bank_account)
        stripe_account = account.student.stripe_customer.bank_accounts.first
        expect(stripe_account).to be_an_instance_of(Stripe::BankAccount)
      end

      it "sets the stripe_id for the credit card instance", :stripe_mock do
        card = FactoryBot.create(:credit_card)
        stripe_card = card.student.stripe_customer.sources.first
        expect(card.stripe_id).to eq stripe_card.id
      end

      it "sets the stripe_id for the bank account instance", :vcr, js: true do
        account = FactoryBot.create(:bank_account)
        stripe_account = account.student.stripe_customer.bank_accounts.first
        expect(account.stripe_id).to eq stripe_account.id
      end

      it "won't save the credit card if it is invalid" do
        credit_card = FactoryBot.build(:invalid_credit_card)
        expect(credit_card.id).to eq nil
      end

      it "gets last four digits of a credit card before_create", :stripe_mock do
        credit_card = FactoryBot.create(:credit_card)
        expect(credit_card.last_four_string).to eq "4242"
      end

      it "gets last four digits of a bank account before_create", :vcr, js: true do
        bank_account = FactoryBot.create(:bank_account)
        expect(bank_account.last_four_string).to eq "6789"
      end

      it "is made the primary payment method if student does not have one", :stripe_mock do
        credit_card = FactoryBot.create(:credit_card)
        expect(credit_card.student.primary_payment_method).to eq credit_card
      end
    end
  end

  describe '.not_verified_first' do
    it 'returns payment methods ordered by not verified', :vcr do
      credit_card = FactoryBot.create(:credit_card)
      bank_account = FactoryBot.create(:bank_account)
      expect(PaymentMethod.not_verified_first).to eq [bank_account, credit_card]
    end
  end

  describe '#description', :stripe_mock do
    let(:student) { FactoryBot.create(:student, :with_credit_card) }

    it 'returns the description for a primary payment method' do
      primary_payment_method = student.primary_payment_method
      expect(primary_payment_method.description).to eq 'Credit card ending in 4242 (Primary)'
    end

    it 'returns the description for a non-primary payment method' do
      non_primary_payment_method = FactoryBot.create(:credit_card, student: student)
      expect(non_primary_payment_method.description).to eq 'Credit card ending in 4242'
    end
  end
end

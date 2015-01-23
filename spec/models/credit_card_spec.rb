describe CreditCard do
  it { should belong_to :student }
  it { should have_many :payments }
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :student_id }

  describe "create create card", :vcr do
    context "with a valid number" do
      let(:credit_card) { FactoryGirl.create :credit_card }

      it "sets verified to 'true' and gets last four digits before_create" do
        credit_card = FactoryGirl.create(:credit_card)
        expect(credit_card.last_four_string).to eq "xxxxxxxxxxxx1111"
        expect(credit_card.verified).to eq true
      end

      it "is made the primary payment method if student does not have one" do
        credit_card = FactoryGirl.create(:credit_card)
        expect(credit_card.student.primary_payment_method).to eq credit_card
      end
    end

    describe "with an invalid number" do
      xit "adds the Balanced message to the errors, except there doesn't seem to be a way to tokenize a card without claiming and authenticating, as happens in balanced.js" do
        credit_card = FactoryGirl.create(:invalid_credit_card)
        expect(credit_card.errors.full_messages).to eq ["This transaction was declined by the card issuer. Customer please call bank."]
      end
    end
  end

  describe "#fetch_balanced_account" do
    it "returns the balanced credit card object", :vcr do
      credit_card = FactoryGirl.create :credit_card
      expect(credit_card.fetch_balanced_account.href).to eq credit_card.account_uri
    end
  end

  describe "#starting_status" do
    it "returns 'succeeded'", :vcr do
      credit_card = FactoryGirl.create :credit_card
      expect(credit_card.starting_status).to eq 'succeeded'
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

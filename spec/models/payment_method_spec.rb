describe PaymentMethod do
  it { should validate_presence_of :student_id }
  it { should belong_to :student }
  it { should have_many :payments }

  describe '.not_verified_first' do
    it 'returns payment methods ordered by not verified', :vcr do
      credit_card = FactoryGirl.create(:credit_card)
      bank_account = FactoryGirl.create(:bank_account)
      expect(PaymentMethod.not_verified_first).to eq [bank_account, credit_card]
    end
  end
end

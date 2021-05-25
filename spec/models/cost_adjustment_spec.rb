describe CostAdjustment do
  it { should belong_to :student }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:reason) }

  describe 'default scope', :stripe_mock do
    it 'orders by created_at ascending' do
      student = FactoryBot.create(:student, :with_credit_card)
      first_adjustment = FactoryBot.create(:cost_adjustment, student: student)
      second_adjustment = FactoryBot.create(:cost_adjustment, student: student)
      expect(CostAdjustment.all).to eq [first_adjustment, second_adjustment]
    end
  end
end

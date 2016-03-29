describe Plan do
  it { should have_many :students }
  it { should validate_presence_of :name }
  it { should validate_presence_of :upfront_amount }
  it { should validate_presence_of :total_amount }

  describe 'active scope' do
    it 'returns all plans that are not archived' do
      plan = FactoryGirl.create(:upfront_payment_only_plan)
      archived_plan = FactoryGirl.create(:upfront_payment_only_plan, archived: true)
      expect(Plan.active).to eq [plan]
    end
  end
end

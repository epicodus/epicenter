describe Plan do
  it { should have_many :students }
  it { should validate_presence_of :name }
  it { should validate_presence_of :upfront_amount }

  describe 'active scope' do
    it 'returns all plans that are not archived' do
      plan = FactoryGirl.create(:upfront_payment_only_plan)
      archived_plan = FactoryGirl.create(:upfront_payment_only_plan, archived: true)
      expect(Plan.active).to eq [plan]
    end
  end

  describe 'standard scope' do
    it 'returns all standard plans' do
      standard_plan = FactoryGirl.create(:standard_plan)
      upfront_plan = FactoryGirl.create(:upfront_payment_only_plan)
      expect(Plan.standard).to eq [standard_plan]
    end
  end

  describe 'upfront scope' do
    it 'returns all upfront plans' do
      upfront_plan = FactoryGirl.create(:upfront_payment_only_plan)
      standard_plan = FactoryGirl.create(:standard_plan)
      expect(Plan.upfront).to eq [upfront_plan]
    end
  end

  describe 'loan scope' do
    it 'returns all loan plans' do
      loan_plan = FactoryGirl.create(:loan_plan)
      standard_plan = FactoryGirl.create(:standard_plan)
      expect(Plan.loan).to eq [loan_plan]
    end
  end

  describe 'parttime scope' do
    it 'returns all part-time plans' do
      parttime_plan = FactoryGirl.create(:parttime_plan)
      standard_plan = FactoryGirl.create(:standard_plan)
      expect(Plan.parttime).to eq [parttime_plan]
    end
  end

  describe 'fulltime scope' do
    it 'returns all full-time plans' do
      standard_plan = FactoryGirl.create(:standard_plan)
      parttime_plan = FactoryGirl.create(:parttime_plan)
      expect(Plan.fulltime).to eq [standard_plan]
    end
  end

  describe 'rates scopes' do
    let!(:rate_plan_2016) { FactoryGirl.create(:rate_plan_2016) }
    let!(:rate_plan_2017) { FactoryGirl.create(:rate_plan_2017) }
    let!(:rate_plan_2018) { FactoryGirl.create(:rate_plan_2018) }

    it 'returns all 2016 plans' do
      expect(Plan.rates_2016).to eq [rate_plan_2016]
    end

    it 'returns all 2017 plans' do
      expect(Plan.rates_2017).to eq [rate_plan_2017]
    end

    it 'returns all 2018 plans' do
      expect(Plan.rates_2018).to eq [rate_plan_2018]
    end
  end
end

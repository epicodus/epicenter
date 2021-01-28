describe Plan do
  it { should have_many :students }
  it { should validate_presence_of :name }
  it { should validate_presence_of :upfront_amount }

  describe 'active scope' do
    it 'returns all plans that are not archived' do
      plan = FactoryBot.create(:upfront_plan)
      archived_plan = FactoryBot.create(:upfront_plan, archived: true)
      expect(Plan.active).to eq [plan]
    end
  end

  describe 'standard scope' do
    it 'returns all standard plans' do
      standard_plan = FactoryBot.create(:standard_plan)
      upfront_plan = FactoryBot.create(:upfront_plan)
      expect(Plan.standard).to eq [standard_plan]
    end
  end

  describe 'upfront scope' do
    it 'returns all upfront plans' do
      upfront_plan = FactoryBot.create(:upfront_plan)
      standard_plan = FactoryBot.create(:standard_plan)
      expect(Plan.upfront).to eq [upfront_plan]
    end
  end

  describe 'loan scope' do
    it 'returns all loan plans' do
      loan_plan = FactoryBot.create(:loan_plan)
      standard_plan = FactoryBot.create(:standard_plan)
      expect(Plan.loan).to eq [loan_plan]
    end
  end

  describe 'isa scope' do
    it 'returns all isa plans' do
      isa_plan = FactoryBot.create(:isa_plan)
      standard_plan = FactoryBot.create(:standard_plan)
      expect(Plan.isa).to eq [isa_plan]
    end
  end

  describe 'parttime scope' do
    it 'returns all part-time plans' do
      parttime_plan = FactoryBot.create(:parttime_plan)
      standard_plan = FactoryBot.create(:standard_plan)
      expect(Plan.parttime).to eq [parttime_plan]
    end
  end

  describe 'fulltime scope' do
    it 'returns all full-time plans' do
      standard_plan = FactoryBot.create(:standard_plan)
      parttime_plan = FactoryBot.create(:parttime_plan)
      expect(Plan.fulltime).to eq [standard_plan]
    end
  end

  describe 'intro scope' do
    it 'returns all free intro plans' do
      intro_plan = FactoryBot.create(:free_intro_plan)
      upfront_plan = FactoryBot.create(:upfront_plan)
      expect(Plan.intro).to eq [intro_plan]
    end
  end

  describe 'fulltime_upfront scope' do
    it 'returns all fulltime upfront plans' do
      intro_plan = FactoryBot.create(:free_intro_plan)
      upfront_plan = FactoryBot.create(:upfront_plan)
      expect(Plan.fulltime_upfront).to eq [upfront_plan]
    end
  end
end

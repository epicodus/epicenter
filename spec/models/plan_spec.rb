describe Plan do
  it { should have_many :students }
  it { should validate_presence_of :name }
  it { should validate_presence_of :recurring_amount }
  it { should validate_presence_of :upfront_amount }
  it { should validate_presence_of :total_amount }
  it { should validate_numericality_of :upfront_amount }
  it { should validate_numericality_of :recurring_amount }
  it { should validate_numericality_of :total_amount }

  describe "#recurring?" do
    it "returns true if the plan is recurring" do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment)
      expect(plan.recurring?).to eq true
    end

    it "returns false if the plan is not recurring" do
      plan = FactoryGirl.create(:upfront_payment_only_plan)
      expect(plan.recurring?).to eq false
    end
  end
end

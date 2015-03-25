describe Company do
  it { should validate_presence_of :name }
  it { should validate_presence_of :contact_phone }
  it { should validate_presence_of :contact_email }
  it { should validate_uniqueness_of :name}

  describe '#last_company?' do
    let!(:company) { FactoryGirl.create(:company) }
    let!(:company_two) { FactoryGirl.create(:company) }

    it "returns true if it is the last company" do
      expect(company_two.last_company?).to be_truthy
    end

    it "returns false if it isn't the last company" do
       expect(company.last_company?).to be_falsey
    end

  end
end

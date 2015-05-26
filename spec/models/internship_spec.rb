describe Internship do
  it { should belong_to :cohort }
  it { should belong_to :company }
  it { should have_many :ratings }
  it { should have_many(:students).through(:ratings) }
  it { should validate_presence_of :cohort_id }
  it { should validate_presence_of :company_id }
  it { should validate_presence_of :description }
  it { should validate_presence_of :ideal_intern }
  it { should validate_uniqueness_of(:company_id).scoped_to(:cohort_id) }

  describe 'default scope' do
    let(:company) { FactoryGirl.create(:company, name: "z labs") }
    let!(:company_two) { FactoryGirl.create(:company, name: "a labs") }
    let!(:company_three) { FactoryGirl.create(:company, name: 'k labs') }

    let!(:internship) { FactoryGirl.create(:internship, company: company) }
    let!(:internship_two) { FactoryGirl.create(:internship, company: company_two) }
    let!(:internship_three) { FactoryGirl.create(:internship, company: company_three) }

    it 'should be organized alphabetically by company name' do
      expect(Internship.all).to eq [internship_two, internship_three, internship]
    end
  end
end

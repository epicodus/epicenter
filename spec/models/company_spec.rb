describe Company do
  it { should have_many :internships }
  it { should validate_presence_of :name }
  it { should validate_presence_of :contact_phone }
  it { should validate_presence_of :contact_email }
  it { should validate_presence_of :website }
  it { should validate_uniqueness_of :name }

  describe 'default scope' do
    let!(:company) { FactoryGirl.create(:company, name: "z labs") }
    let!(:company_two) { FactoryGirl.create(:company, name: "a labs") }
    let!(:company_three) { FactoryGirl.create(:company, name: 'k labs') }

    it 'should be organized alphabetically by name' do

      expect(Company.all).to eq [company_two, company_three, company]
    end
  end

  describe '#fix_url' do
    context 'with a valid uri scheme' do
      it "doesn't prepend 'http://' to the url when it starts with 'http:/" do
        company = FactoryGirl.create(:company, website: 'http://www.test.com')
        expect(company.website).to eq 'http://www.test.com'
      end
    end

    context 'with an invalid uri scheme' do
      it "prepends 'http://' to the url when it doesn't start with 'http" do
        company = FactoryGirl.create(:company, website: 'www.test.com')
        expect(company.website).to eq 'http://www.test.com'
      end
    end
  end

end

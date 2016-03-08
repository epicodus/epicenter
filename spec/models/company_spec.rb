describe Company do
  it { should have_many :internships }

  describe "abilities" do
    let(:company) { FactoryGirl.create(:company) }
    subject { Ability.new(company, '::1') }

    context 'for companies' do
      it { is_expected.to have_abilities(:manage, Company.new(id: company.id))}
      it { is_expected.to_not have_abilities(:manage, Company.new)}
    end

    context 'for internships' do
      it { is_expected.to have_abilities(:manage, Internship.new(company_id: company.id)) }
      it { is_expected.to_not have_abilities(:manage, Internship.new) }
    end
  end
end

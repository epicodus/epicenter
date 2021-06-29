describe Admin do
  it { should belong_to(:current_course).optional }
  it { should have_many :courses }
  it { should have_many :cohorts }
  it { should have_many :submissions }

  describe "default scope" do
    it "alphabetizes the admins by name" do
      admin1 = FactoryBot.create(:admin, name: "Bob Test")
      admin2 = FactoryBot.create(:admin, name: "Annie Test")
      expect(Admin.all).to eq [admin2, admin1]
    end
  end

  describe '#teachers' do
    it 'returns all admins with teacher flag' do
      FactoryBot.create(:admin)
      teacher = FactoryBot.create(:admin, teacher: true)
      expect(Admin.teachers).to eq [teacher]
    end
  end

  describe "abilities" do
    let(:admin) { FactoryBot.create(:admin) }
    subject { Ability.new(admin, "::1") }

    context 'for code reviews' do
      it { is_expected.to have_abilities(:manage, CodeReview.new) }
    end

    context 'for submissions' do
      it { is_expected.to have_abilities(:manage, Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to have_abilities([:create], Review.new) }
    end

    context 'for bank_accounts' do
      it { is_expected.to not_have_abilities(:create, BankAccount.new) }
    end

    context 'for credit_cards' do
      it { is_expected.to not_have_abilities(:create, CreditCard.new) }
    end

    context 'for payments' do
      it { is_expected.to have_abilities([:manage], Payment.new) }
    end

    context 'for courses' do
      it { is_expected.to have_abilities(:manage, Course.new) }
    end

    context 'for attendance record amendments' do
      it { is_expected.to have_abilities(:create, AttendanceRecordAmendment.new) }
    end

    context 'for companies' do
      it { is_expected.to have_abilities(:manage, Company.new) }
    end

    context 'for internships' do
      it { is_expected.to have_abilities(:manage, Internship.new) }
    end

    context 'for interview assignments' do
      it { is_expected.to have_abilities(:manage, InterviewAssignment.new) }
    end

    context 'for internship assignments' do
      it { is_expected.to have_abilities(:manage, InternshipAssignment.new) }
    end

    context 'for students' do
      it { is_expected.to have_abilities(:manage, Student.new) }
    end
  end

  it 'is assigned a default current_course before creation' do
    FactoryBot.create(:pt_intro_cohort)
    admin = FactoryBot.create(:admin)
    expect(admin.current_course).to be_a Course
  end

  it 'defaults to last course if no current_course_id saved' do
    admin = FactoryBot.create(:admin)
    course = FactoryBot.create(:course)
    admin.courses << course
    expect(admin.current_course_id).to eq nil
    expect(admin.current_course).to eq course
  end
end

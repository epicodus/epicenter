describe Admin do
  it { should belong_to :current_course }

  describe "abilities" do
    let(:admin) { FactoryGirl.create(:admin) }
    subject { Ability.new(admin, "::1") }

    context 'for code reviews' do
      it { is_expected.to have_abilities(:manage, CodeReview.new) }
    end

    context 'for submissions' do
      it { is_expected.to have_abilities(:read, Submission.new) }
      it { is_expected.to not_have_abilities([:create, :update], Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to have_abilities([:create], Review.new) }
    end

    context 'for course_attendance_statistics' do
      it { is_expected.to have_abilities(:read, CourseAttendanceStatistics) }
    end

    context 'for bank_accounts' do
      it { is_expected.to not_have_abilities(:create, BankAccount.new) }
    end

    context 'for credit_cards' do
      it { is_expected.to not_have_abilities(:create, CreditCard.new) }
    end

    context 'for payments', vcr: true do
      it { is_expected.to not_have_abilities([:create, :update], Payment.new) }
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

    context 'for students' do
      it { is_expected.to have_abilities(:read, Student.new) }
    end
  end

  it 'is assigned a default current_course before creation' do
    FactoryGirl.create(:course)
    admin = FactoryGirl.build(:admin, current_course: nil)
    admin.save
    expect(admin.current_course).to be_a Course
  end
end

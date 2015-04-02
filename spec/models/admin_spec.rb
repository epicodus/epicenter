describe Admin do
  it { should belong_to :current_cohort }

  describe "abilities" do
    let(:admin) { FactoryGirl.create(:admin) }
    subject { Ability.new(admin) }

    context 'for assessments' do
      it { is_expected.to have_abilities(:manage, Assessment.new) }
    end

    context 'for submissions' do
      it { is_expected.to have_abilities(:read, Submission.new) }
      it { is_expected.to not_have_abilities([:create, :update], Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to have_abilities([:create], Review.new) }
    end

    context 'for cohort_attendance_statistics' do
      it { is_expected.to have_abilities(:read, CohortAttendanceStatistics) }
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

    context 'for verifications', vcr: true do
      it { is_expected.to not_have_abilities(:update, Verification.new) }
    end

    context 'for cohorts' do
      it { is_expected.to have_abilities(:manage, Cohort.new) }
    end

    context 'for attendance record amendments' do
      it { is_expected.to have_abilities(:create, AttendanceRecordAmendment.new) }
    end

    context 'for companies' do
      it { is_expected.to have_abilities(:manage, Company.new) }
    end
  end

  it 'is assigned a default current_cohort before creation' do
    FactoryGirl.create(:cohort)
    admin = FactoryGirl.build(:admin, current_cohort: nil)
    admin.save
    expect(admin.current_cohort).to be_a Cohort
  end
end

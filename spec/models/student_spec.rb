describe Student do
  it { should validate_presence_of :plan_id }
  it { should validate_presence_of :cohort_id }
  it { should have_many :bank_accounts }
  it { should have_many :payment_methods }
  it { should have_many :credit_cards }
  it { should have_many :payments }
  it { should belong_to :plan }
  it { should have_many :attendance_records }
  it { should belong_to :cohort }

  describe "#payment_methods" do
    it "returns all the student's bank accounts and credit cards", :vcr do
      student = FactoryGirl.create(:student)
      credit_card_1 = FactoryGirl.create(:credit_card, student: student)
      credit_card_2 = FactoryGirl.create(:credit_card, student: student)
      bank_account = FactoryGirl.create(:bank_account, student: student)
      expect(student.payment_methods).to match_array [credit_card_1, credit_card_2, bank_account]
    end
  end

  describe "#payment_methods_primary_first_then_pending" do
    it "returns payment methods with primary first, then pending bank accounts", :vcr do
      student = FactoryGirl.create(:student)
      credit_card_1 = FactoryGirl.create(:credit_card, student: student)
      bank_account = FactoryGirl.create(:bank_account, student: student)
      credit_card_2 = FactoryGirl.create(:credit_card, student: student)
      expect(student.payment_methods_primary_first_then_pending[0]).to eq credit_card_1
      expect(student.payment_methods_primary_first_then_pending[1]).to eq bank_account
    end
  end

  describe ".recurring_active" do
    it "only includes users that are recurring_active", :vcr do
      recurring_active_user = FactoryGirl.create(:user_with_recurring_active)
      non_recurring_active_user  = FactoryGirl.create(:user_with_verified_bank_account)
      expect(Student.recurring_active).to eq [recurring_active_user]
    end
  end

  describe "#upfront_payment_due?", :vcr do
    let(:student) { FactoryGirl.create :user_with_verified_bank_account }

    it "is true if student has upfront payment and no payments have been made" do
      expect(student.upfront_payment_due?).to be true
    end

    it "is false if student has no upfront payment" do
      student.plan.upfront_amount = 0
      expect(student.upfront_payment_due?).to be false
    end

    it "is false if student has made any payments" do
      student = FactoryGirl.create :user_with_upfront_payment
      expect(student.upfront_payment_due?).to be false
    end
  end

  describe "#ready_to_start_recurring_payments?", :vcr do
    let(:student) { FactoryGirl.create :user_with_verified_bank_account }

    it "is true if student has a recurring plan, recurring is not active and no upfront payment is due" do
      plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment)
      student = FactoryGirl.create(:student, plan: plan)
      expect(student.ready_to_start_recurring_payments?).to be true
    end

    it "is false if student has upfront payment due" do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment)
      student = FactoryGirl.create(:student, plan: plan)
      expect(student.ready_to_start_recurring_payments?).to be false
    end

    it "is false if student does not have a plan with recurring payments" do
      plan = FactoryGirl.create(:upfront_payment_only_plan)
      student = FactoryGirl.create(:user_with_upfront_payment, plan: plan)
      expect(student.ready_to_start_recurring_payments?).to be false
    end

    it "is false if recurring is active" do
      student = FactoryGirl.create(:user_with_recurring_active)
      expect(student.ready_to_start_recurring_payments?).to be false
    end
  end

  describe "#make_upfront_payment", :vcr do
    it "makes a payment for the upfront amount of the student's plan" do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      student.make_upfront_payment
      expect(student.payments.first.amount).to eq student.plan.upfront_amount
    end
  end

  describe "#start_recurring_payments", :vcr do
    it "makes a payment for the recurring amount of the users's plan" do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      student.start_recurring_payments
      expect(student.payments.first.amount).to eq student.plan.recurring_amount
    end

    it 'sets the bank account to be recurring_active' do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      student.start_recurring_payments
      expect(student.recurring_active).to eq true
    end
  end

  describe "#recurring_amount_with_fees", :vcr do
    let(:plan) { FactoryGirl.create(:recurring_plan_with_upfront_payment, recurring_amount: 600_00) }

    it "calculates the total recurring amount for a credit card" do
      student = FactoryGirl.create(:user_with_credit_card, plan: plan)
      expect(student.recurring_amount_with_fees).to eq 618_21
    end

    it 'calculates the total recurring amount for a bank account' do
      student = FactoryGirl.create(:user_with_verified_bank_account, plan: plan)
      expect(student.recurring_amount_with_fees).to eq 600_00
    end
  end

  describe "#upfront_amount_with_fees", :vcr do
    it "calculates the total upfront amount" do
      plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, upfront_amount: 200_00)
      student = FactoryGirl.create(:user_with_credit_card, plan: plan)
      expect(student.upfront_amount_with_fees).to eq 206_27
    end
  end

  describe '#signed_in_today?' do
    let(:student) { FactoryGirl.create(:student) }

    it 'is false if the student has not signed in today' do
      expect(student.signed_in_today?).to eq false
    end

    it 'is true if the student has already signed in today' do
      attendance_record = FactoryGirl.create(:attendance_record, student: student)
      expect(student.signed_in_today?).to eq true
    end
  end

  describe "#primary_payment_method", :vcr do
    it "returns the student's primary payment method" do
      student = FactoryGirl.create(:student)
      credit_card = FactoryGirl.create(:credit_card)
      student.set_primary_payment_method(credit_card)
      expect(student.primary_payment_method).to eq credit_card
    end

    it "returns nil if student does not have a primary payment method" do
      student = FactoryGirl.create(:user_with_unverified_bank_account)
      expect(student.primary_payment_method).to eq nil
    end
  end

  describe "#set_primary_payment_method", :vcr do
    it "sets the primary payment method of the student" do
      student = FactoryGirl.create(:student)
      credit_card = FactoryGirl.create(:credit_card)
      student.set_primary_payment_method(credit_card)
      expect(student.primary_payment_method).to eq credit_card
    end
  end

  describe '#class_in_session?' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student) { FactoryGirl.create(:student, cohort: cohort) }

    it 'returns false for a date before class starts' do
      travel_to cohort.start_date.to_date - 1.day do
        expect(student.class_in_session?).to eq false
      end
    end

    it 'returns false for a date after class ends' do
      travel_to cohort.end_date.to_date + 1.day do
        expect(student.class_in_session?).to eq false
      end
    end

    it 'returns true for a date during class' do
      travel_to cohort.start_date.to_date do
        expect(student.class_in_session?).to eq true
      end

      travel_to cohort.start_date.to_date + 2.weeks do
        expect(student.class_in_session?).to eq true
      end
    end
  end

  describe '#class_over?' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student) { FactoryGirl.create(:student, cohort: cohort) }

    it 'returns false before class is over' do
      travel_to cohort.end_date.to_date - 5.days do
        expect(student.class_over?).to eq false
      end
    end

    it 'returns true after class ends' do
      travel_to cohort.end_date.to_date + 1.day do
        expect(student.class_over?).to eq true
      end
    end
  end

  describe 'attendance methods' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student) { FactoryGirl.create(:student, cohort: cohort) }

    describe '#on_time_attendances' do
      it 'counts the number of days the student has been on time to class' do
        travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
          FactoryGirl.create(:attendance_record, student: student)
          expect(student.on_time_attendances).to eq 1
        end
      end
    end

    describe '#tardies' do
      it 'counts the number of days the student has been tardy' do
        travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 9, 10, 00) do
          FactoryGirl.create(:attendance_record, student: student)
          travel 1.day
          FactoryGirl.create(:attendance_record, student: student)
          expect(student.tardies).to eq 2
        end
      end
    end

    describe '#absences' do
      it 'counts the number of days the student has been absent' do
        travel_to cohort.start_date do
          travel 1.day
          FactoryGirl.create(:attendance_record, student: student)
          expect(student.absences).to eq 1
        end
      end
    end
  end

  describe "#next_payment_date", :vcr do
    it "returns nil if recurring_active is not true" do
      student = FactoryGirl.create(:user_with_upfront_payment)
      expect(student.next_payment_date).to eq nil
    end

    it "returns the next payment date if recurring_active is true" do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      expect(student.next_payment_date.to_date).to eq Date.parse("February 5, 2014")
    end
  end

  describe "abilities" do
    let(:student) { FactoryGirl.create(:student) }
    subject { Ability.new(student) }

    context 'for assessments' do
      it { is_expected.to have_abilities(:read, Assessment.new(cohort: student.cohort)) }
      it { is_expected.to not_have_abilities(:read, Assessment.new) }
    end

    context 'for submissions' do
      it { is_expected.to not_have_abilities(:create, Submission.new) }
      it { is_expected.to have_abilities(:create, Submission.new(student: student)) }
      it { is_expected.to have_abilities(:update, Submission.new(student: student)) }
      it { is_expected.to not_have_abilities(:update, Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Review.new) }
    end

    context 'for cohort_attendance_statistics' do
      it { is_expected.to not_have_abilities(:read, CohortAttendanceStatistics) }
    end

    context 'for student_attendance_statistics' do
      it { is_expected.to have_abilities(:read, StudentAttendanceStatistics.new(student)) }
      it { is_expected.to not_have_abilities(:read, StudentAttendanceStatistics.new(Student.new)) }
    end

    context 'for bank_accounts' do
      it { is_expected.to have_abilities(:create, BankAccount.new) }
    end

    context 'for credit_cards' do
      it { is_expected.to have_abilities(:create, CreditCard.new) }
    end


    context 'for payments', vcr: true do
      let(:bank_account) { FactoryGirl.create(:bank_account, student: student) }
      let(:credit_card) { FactoryGirl.create(:credit_card, student: student) }

      it 'allows students to create payments using one of their payment methods' do
        is_expected.to have_abilities(:create, Payment.new(payment_method: bank_account, student_id: student.id))
        is_expected.to have_abilities(:create, Payment.new(payment_method: credit_card, student_id: student.id))
      end

      it "doesn't allow students to create payments for others' payment methods" do
        another_bank_account = FactoryGirl.create(:bank_account)
        another_credit_card = FactoryGirl.create(:credit_card)
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_bank_account))
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_credit_card))
      end
      it { is_expected.to not_have_abilities(:create, Payment.new(payment_method: bank_account)) }

      it { is_expected.to have_abilities(:read, Payment.new(student: student)) }
      it { is_expected.to not_have_abilities(:read, Payment.new) }
    end

    context 'for verifications', vcr: true do
      it 'allows students to verify their own bank accounts' do
        bank_account = FactoryGirl.create(:bank_account, student: student)
        is_expected.to have_abilities(:update, Verification.new(bank_account: bank_account))
      end

      it { is_expected.to not_have_abilities(:update, Verification.new) }
    end
  end
end

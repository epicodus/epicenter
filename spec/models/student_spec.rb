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

  describe ".billable_today", :vcr do
    it "includes users that have not been billed in the last month" do
      student = FactoryGirl.create(:user_with_recurring_due)
      expect(Student.billable_today).to eq [student]
    end

    it "does not include users that have been billed in the last month" do
      bank_account = FactoryGirl.create(:user_with_recurring_not_due)
      expect(Student.billable_today).to eq []
    end

    it "doesn't matter if previous payments get updated" do
      student = FactoryGirl.create(:user_with_recurring_not_due)
      old_payment = FactoryGirl.create(:payment, student: student, created_at: 6.weeks.ago)
      newer_payment = FactoryGirl.create(:payment, student: student, created_at: 2.weeks.ago)
      old_payment.update(updated_at: Date.today)
      expect(Student.billable_today).to eq []
    end

    it "only includes users that are recurring_active" do
      student = FactoryGirl.create(:user_with_recurring_due)
      student.update(recurring_active: false)
      expect(Student.billable_today).to eq []
    end

    it "returns all users that are due for payment" do
      student1 = FactoryGirl.create(:user_with_recurring_due)
      student2 = FactoryGirl.create(:user_with_recurring_due)
      student3 = FactoryGirl.create(:user_with_recurring_not_due)
      student4 = FactoryGirl.create(:user_with_recurring_due)
      student4.update(recurring_active: false)
      expect(Student.billable_today).to match_array [student1, student2]
    end

    it "handles months with different amounts of days" do
      student = nil
      travel_to(Date.parse("January 31, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("March 1, 2014")) do
        expect(Student.billable_today).to eq [student]
      end
    end
  end

  describe ".billable_in_three_days", :vcr do
    it 'tells you which users are billable in three days' do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(Student.billable_in_three_days).to eq [student]
      end
    end

    it 'works even if the payment is made at a different time than the method is run' do
      student = nil
      travel_to(Time.new(2014, 1, 5, 12, 0, 0, 0)) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Time.new(2014, 2, 2, 15, 0, 0, 0)) do
        expect(Student.billable_in_three_days).to eq [student]
      end
    end

    it 'does not include users that are billable in more than three days' do
      student = nil
      travel_to(Date.parse("January 6, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(Student.billable_in_three_days).to eq []
      end
    end

    it 'does not include users that are billable in less than three days' do
      student = nil
      travel_to(Date.parse("January 4, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end
      travel_to(Date.parse("February 2, 2014")) do
        expect(Student.billable_in_three_days).to eq []
      end
    end
  end

  describe ".email_upcoming_payees" do
    it "emails users who are due in 3 days", :vcr do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active)
      end

      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }

      travel_to(Date.parse("February 2, 2014")) do
        Student.email_upcoming_payees
      end

      expect(mailgun_client).to have_received(:send_message).with(
        "epicodus.com",
        { :from => "michael@epicodus.com",
          :to => student.email,
          :bcc => "michael@epicodus.com",
          :subject => "Upcoming Epicodus tuition payment",
          :text => "Hi #{student.name}. This is just a reminder that your next Epicodus tuition payment will be withdrawn from your bank account in 3 days. If you need anything, reply to this email. Thanks!" }
      )
    end
  end

  describe ".bill_bank_accounts", :vcr do
    it "bills all bank_accounts that are due today" do
      student = FactoryGirl.create(:user_with_recurring_due)
      expect { Student.bill_bank_accounts }.to change { student.payments.count }.by 1
    end

    it "does not bill bank accounts that are not due today" do
      student = FactoryGirl.create(:user_with_recurring_not_due)
      expect { Student.bill_bank_accounts }.to change { student.payments.count }.by 0
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
      it { is_expected.to have_abilities(:read, Assessment.new) }
    end

    context 'for submissions' do
      it { is_expected.to have_abilities(:create, Submission.new) }
      it { is_expected.to have_abilities(:update, Submission.new(student: student)) }
      it { is_expected.to not_have_abilities(:update, Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Review.new) }
    end

    context 'for cohort_attendance_statistics' do
      it { is_expected.to not_have_abilities(:read, CohortAttendanceStatistics) }
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
        is_expected.to have_abilities(:create, Payment.new(payment_method: bank_account))
        is_expected.to have_abilities(:create, Payment.new(payment_method: credit_card))
      end

      it "doesn't allow students to create payments for others' payment methods" do
        another_bank_account = FactoryGirl.create(:bank_account)
        another_credit_card = FactoryGirl.create(:credit_card)
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_bank_account))
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_credit_card))
      end
      it { is_expected.to have_abilities(:create, Payment.new(payment_method: bank_account)) }

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

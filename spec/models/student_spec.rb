require 'rails_helper'

describe Student do
  it { should validate_presence_of :plan_id }
  it { should validate_presence_of :cohort_id }
  it { should have_many :bank_accounts }
  it { should have_many :payments }
  it { should belong_to :plan }
  it { should have_many :attendance_records }
  it { should belong_to :cohort }

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

    include ActiveSupport::Testing::TimeHelpers
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
    include ActiveSupport::Testing::TimeHelpers
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
    include ActiveSupport::Testing::TimeHelpers

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
      expect(student.primary_payment_method_type).to eq 'CreditCard'
      expect(student.primary_payment_method_id).to eq credit_card.id
    end
  end

  describe 'attendance methods' do
    include ActiveSupport::Testing::TimeHelpers

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

  describe "#has_payment_method", :vcr do
    it "returns true if student has a credit card" do
      student = FactoryGirl.create(:user_with_credit_card)
      expect(student.has_payment_method).to eq true
    end

    it "returns true if student has a verified bank account" do
      student = FactoryGirl.create(:user_with_verified_bank_account)
      expect(student.has_payment_method).to eq true
    end

    it "returns false if student has no credit card and unverified bank account" do
      student = FactoryGirl.create(:user_with_unverified_bank_account)
      expect(student.has_payment_method).to eq false
    end

    it "returns false if student doesn't have a credit card or bank account" do
      student = FactoryGirl.create(:student)
      expect(student.has_payment_method).to eq false
    end
  end

  describe "#next_payment_date", :vcr do
    include ActiveSupport::Testing::TimeHelpers
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

    it { is_expected.to be_able_to(:read, Assessment.new) }
  end
end

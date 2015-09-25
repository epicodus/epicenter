describe Student do
  it { should validate_presence_of :plan_id }
  it { should validate_presence_of :cohort_id }
  it { should have_many :bank_accounts }
  it { should have_many :payment_methods }
  it { should have_many :credit_cards }
  it { should have_many :payments }
  it { should have_many :ratings }
  it { should have_many(:internships).through(:ratings) }
  it { should belong_to :plan }
  it { should have_many :attendance_records }
  it { should belong_to :cohort }
  it { should belong_to(:primary_payment_method).class_name('PaymentMethod') }
  it { should have_many :signatures }

  describe "#pair_on_day" do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student_1) { FactoryGirl.create(:student, cohort: cohort) }
    let(:student_2) { FactoryGirl.create(:student, cohort: cohort) }

    it "returns the pair partner" do
      attendance_record = FactoryGirl.create(:attendance_record, student: student_1, pair_id: student_2.id)
      expect(student_1.pair_on_day(attendance_record.date)).to eq student_2
    end

    it "returns nil if a student has no pair for the day" do
      attendance_record_1 = FactoryGirl.create(:attendance_record, student: student_1)
      expect(student_1.pair_on_day(attendance_record_1.date)).to eq nil
    end
  end

  describe "#attendance_record_on_day" do
    let(:student) { FactoryGirl.create(:student) }
    let(:attendance_record) { FactoryGirl.create(:attendance_record, student: student) }

    it "returns the student's attendance record for the specified day" do
      expect(student.attendance_record_on_day(attendance_record.date)).to eq attendance_record
    end
  end

  describe "#random_pairs" do
    before do
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }
    end

    let!(:current_student) { FactoryGirl.create(:student) }
    let!(:student_2) { FactoryGirl.create(:user_with_score_of_9, cohort: current_student.cohort) }
    let!(:student_3) { FactoryGirl.create(:user_with_score_of_10, cohort: current_student.cohort) }
    let!(:student_4) { FactoryGirl.create(:user_with_score_of_10, cohort: current_student.cohort) }
    let!(:student_5) { FactoryGirl.create(:user_with_score_of_10, cohort: current_student.cohort) }
    let!(:student_6) { FactoryGirl.create(:user_with_score_of_10, cohort: current_student.cohort) }
    let!(:student_7_after_starting_point) { FactoryGirl.create(:user_with_score_of_10, cohort: current_student.cohort) }
    let!(:student_8) { FactoryGirl.create(:user_with_score_of_6, cohort: current_student.cohort) }
    let!(:student_9) { FactoryGirl.create(:user_with_score_of_6, cohort: current_student.cohort) }
    let!(:student_10_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, cohort: current_student.cohort) }
    let!(:student_11_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, cohort: current_student.cohort) }
    let!(:student_12_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, cohort: current_student.cohort) }

    it "returns an empty array when there are no other students in a cohort" do
      new_cohort = FactoryGirl.create(:cohort)
      current_student.update(cohort: new_cohort)
      expect(current_student.random_pairs).to eq []
    end

    it "returns random pairs based on student total grade score for the most recent code review and distance_until_end is more than the number of pairs" do
      allow(current_student).to receive(:latest_total_grade_score).and_return(10)
      allow(current_student).to receive(:random_starting_point).and_return(1)
      expect(current_student.random_pairs).to eq [student_3, student_4, student_5, student_6, student_7_after_starting_point]
    end

    it "returns random pairs based on student total grade score for the most recent code review and distance_until_end is less than the number of pairs" do
      allow(current_student).to receive(:latest_total_grade_score).and_return(10)
      allow(current_student).to receive(:random_starting_point).and_return(5)
      expect(current_student.random_pairs).to eq [student_7_after_starting_point, student_2, student_3, student_4, student_5]
    end

    it "returns random pairs when the student total grade score is nil and distance_until_end is less than the number of pairs" do
      allow(current_student).to receive(:random_starting_point).and_return(8)
      expect(current_student.random_pairs).to eq [student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point, student_2, student_3]
    end

    it "returns random pairs when the student total grade score is nil and distance_until_end is more than the number of pairs" do
      allow(current_student).to receive(:random_starting_point).and_return(6)
      expect(current_student.random_pairs).to eq [student_8, student_9, student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point]
    end
  end

  describe "#latest_total_grade_score" do
    let(:student) { FactoryGirl.create(:student) }
    let(:submission) { FactoryGirl.create(:submission, student: student) }

    before do
      mailgun_client = spy("mailgun client")
      allow(Mailgun::Client).to receive(:new) { mailgun_client }
    end

    it 'returns nil when a student has not submitted a code review' do
      expect(student.latest_total_grade_score).to eq nil
    end

    it 'returns a total grade score for the latest code review when a student has received a grade' do
      FactoryGirl.create(:passing_review, student: student, submission: submission)
      expect(student.latest_total_grade_score).to eq 3
    end

    it 'returns an aggregate total grade score for the latest code review when a student has received multiple grades' do
      review = FactoryGirl.create(:passing_review, student: student, submission: submission)
      objective = FactoryGirl.create(:objective)
      FactoryGirl.create(:failing_grade, review: review, objective: objective )
      expect(student.latest_total_grade_score).to eq 4
    end
  end

  describe "updating close.io" do
    let(:student) { FactoryGirl.create(:student, email: 'test@test.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { close_io_client.list_leads('email:' + student.email).data.first.id }

    before do
      allow(student).to receive(:close_io_client).and_return(close_io_client)
    end

    it "updates the record when there are enough signatures and a payment has been made", :vcr do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      allow(student).to receive(:total_paid).and_return(340000)
      expect(close_io_client).to receive(:update_lead).with(lead_id, { status: "Enrolled", 'custom.Amount paid': student.total_paid / 100 })
      student.update_close_io
    end

    it "fails to update the record when there are not enough signatures", :vcr do
      student.update(email: 'fake@fake.com')
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      allow(student).to receive(:total_paid).and_return(100)
      expect { student.update_close_io }.to raise_error(RuntimeError, 'The Close.io lead for fake@fake.com was not found.')
    end

    it "fails to update the record when no payment has been made", :vcr do
      student.update(email: 'fake@fake.com')
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      allow(student).to receive(:total_paid).and_return(0)
      expect { student.update_close_io }.to raise_error(RuntimeError, 'The Close.io lead for fake@fake.com was not found.')
    end
  end

  describe "#signed?" do
    let(:student) { FactoryGirl.create(:student) }

    it "returns true if a signature has been signed" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      expect(student.signed?(CodeOfConduct)).to eq true
    end

    it "returns true if a signature is nil" do
      expect(student.signed?(nil)).to eq true
    end

    it "returns false if a signature has not been signed" do
      expect(student.signed?(RefundPolicy)).to be false
    end
  end

  describe "#signed_main_documents?" do
    let(:student) { FactoryGirl.create(:student) }

    it "returns true if all 3 main documents have been signed" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      expect(student.signed_main_documents?).to eq true
    end

    it "returns false if all 3 main documents have not been signed" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      expect(student.signed_main_documents?).to eq false
    end
  end

  describe "default scope" do
    it "alphabetizes the students by name" do
      student1 = FactoryGirl.create(:student, name: "Bob Test")
      student2 = FactoryGirl.create(:student, name: "Annie Test")
      expect(Student.all).to eq [student2, student1]
    end
  end

  it "validates that the primary payment method belongs to the user", :vcr do
    student = FactoryGirl.create(:student)
    other_students_credit_card = FactoryGirl.create(:credit_card)
    student.primary_payment_method = other_students_credit_card
    expect(student.valid?).to be false
  end

  describe "#stripe_customer" do
    it "creates a Stripe Customer object for a student", :vcr do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns the Stripe Customer object", :vcr do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns a Stripe Customer object if one already exists", :vcr do
      student = FactoryGirl.create(:student)
      first_stripe_customer_return = student.stripe_customer
      second_stripe_customer_return = student.stripe_customer
      expect(first_stripe_customer_return.id).to eq second_stripe_customer_return.id
    end
  end

  describe "#stripe_customer_id" do
    it "starts out nil", :vcr do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer_id).to be_nil
    end

    it "is populated when a Stripe Customer object is created", :vcr do
      student = FactoryGirl.create(:student)
      stripe_customer = student.stripe_customer
      expect(student.stripe_customer_id).to eq stripe_customer.id
    end
  end

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
      recurring_active_user = FactoryGirl.create(:user_with_recurring_active, email: 'test@test.com')
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
      student = FactoryGirl.create :user_with_upfront_payment, email: 'test@test.com'
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
      student = FactoryGirl.create(:user_with_upfront_payment, plan: plan, email: 'test@test.com')
      expect(student.ready_to_start_recurring_payments?).to be false
    end

    it "is false if recurring is active" do
      student = FactoryGirl.create(:user_with_recurring_active, email: 'test@test.com')
      expect(student.ready_to_start_recurring_payments?).to be false
    end
  end

  describe "#make_upfront_payment", :vcr do
    it "makes a payment for the upfront amount of the student's plan" do
      student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com')
      student.make_upfront_payment
      expect(student.payments.first.amount).to eq student.plan.upfront_amount
    end
  end

  describe "#start_recurring_payments", :vcr do
    it "makes a payment for the recurring amount of the users's plan" do
      student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com')
      student.start_recurring_payments
      expect(student.payments.first.amount).to eq student.plan.recurring_amount
    end

    it 'sets the bank account to be recurring_active' do
      student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com')
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

  describe '#signed_out_today?' do
    let(:student) { FactoryGirl.create(:student) }

    it 'is false if the student has not signed out today' do
      attendance_record = FactoryGirl.create(:attendance_record, student: student)
      expect(student.signed_out_today?).to eq false
    end

    it 'is true if the student has signed out' do
      attendance_record = FactoryGirl.create(:attendance_record, student: student)
      attendance_record.update({:signing_out => true})
      expect(student.signed_out_today?).to eq true
    end

    it 'populates the signed_out_time field for a students attendance record' do
      attendance_record = FactoryGirl.create(:attendance_record, student: student)
      attendance_record.update({:signing_out => true})
      expect(attendance_record.signed_out_time).to_not eq nil
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
          attendance_record = FactoryGirl.create(:attendance_record, student: student)
          travel 15.hours do
            attendance_record.update({:signing_out => true})
            expect(student.on_time_attendances).to eq 1
          end
        end
      end
    end

    describe '#tardies' do
      it 'counts the number of days the student has been tardy' do
        travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 9, 10, 00, Time.zone.formatted_offset) do
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

    describe '#left_earlies' do
      it 'counts the number of days the student has left early (failed to sign out)' do
        travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
          attendance_record = FactoryGirl.create(:attendance_record, student: student)
          travel 7.hours do
            attendance_record.update({:signing_out => true})
            expect(student.left_earlies).to eq 1
          end
        end
      end
    end
  end

  describe "#next_payment_date", :vcr do
    it "returns nil if recurring_active is not true" do
      student = FactoryGirl.create(:user_with_upfront_payment, email: 'test@test.com')
      expect(student.next_payment_date).to eq nil
    end

    it "returns the next payment date if recurring_active is true" do
      student = nil
      travel_to(Date.parse("January 5, 2014")) do
        student = FactoryGirl.create(:user_with_recurring_active, email: 'test@test.com')
      end
      expect(student.next_payment_date.to_date).to eq Date.parse("February 5, 2014")
    end
  end

  describe '#total_paid', :vcr do
    it 'sums all of the students payments' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      FactoryGirl.create(:payment, student: student, amount: 200_00)
      FactoryGirl.create(:payment, student: student, amount: 200_00)
      expect(student.total_paid).to eq 400_00
    end

    it 'does not include failed payments' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'test@test.com')
      FactoryGirl.create(:payment, student: student, amount: 200_00)
      failed_payment = FactoryGirl.create(:payment, student: student, amount: 200_00)
      failed_payment.update(status: 'failed')
      expect(student.total_paid).to eq 200_00
    end
  end

  describe '#find_rating' do
    it 'finds the rating based on internship' do
      student = FactoryGirl.create(:student)
      internship = FactoryGirl.create(:internship)
      rating = FactoryGirl.create(:rating, student: student, internship: internship)
      expect(student.find_rating(internship)).to eq(rating)
    end
  end

  describe 'find_students_by_interest' do
    let(:student) { FactoryGirl.create(:student) }
    let(:internship) { FactoryGirl.create(:internship, cohort: student.cohort) }

    it 'returns an array of students in an internship that share an interest level in that internship' do
      FactoryGirl.create(:rating, interest: '1', internship: internship, student: student)
      expect(Student.find_students_by_interest(internship, '1')).to eq([student])
    end

    it 'it doesn;t return students that do not share the interest level in an internship' do
      FactoryGirl.create(:rating, interest: '1', internship: internship, student: student)
      expect(Student.find_students_by_interest(internship, '2')).to_not eq([student])
    end

    it 'will take into account an internship that has not been rated an interest level' do
      expect(Student.find_students_by_interest(internship, '')).to eq ([])
    end
  end

  describe "abilities" do
    let(:student) { FactoryGirl.create(:student) }
    subject { Ability.new(student) }

    context 'for code reviews' do
      it { is_expected.to have_abilities(:read, CodeReview.new(cohort: student.cohort)) }
      it { is_expected.to not_have_abilities(:read, CodeReview.new) }
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

      it "doesn't allow students to create payments for other students" do
        bank_account = FactoryGirl.create(:bank_account, student: student)
        another_student = FactoryGirl.create(:student)
        is_expected.to not_have_abilities(:create, Payment.new(student: another_student, payment_method: bank_account))
      end

      it { is_expected.to not_have_abilities(:create, Payment.new(payment_method: bank_account)) }

      it { is_expected.to have_abilities(:read, Payment.new(student: student)) }
      it { is_expected.to not_have_abilities(:read, Payment.new) }
    end

    context 'for companies' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Company.new)}
    end

    context 'for internships' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Internship.new)}
      it { is_expected.to have_abilities(:read, Internship.new(cohort: student.cohort)) }
    end

    context 'for students' do
      it { is_expected.to not_have_abilities(:read, Student.new) }
    end

    context 'for transcripts' do
      it { is_expected.to have_abilities(:read, Transcript.new(student)) }
      it { is_expected.to not_have_abilities(:read, Transcript.new(Student.new)) }
    end
  end
end

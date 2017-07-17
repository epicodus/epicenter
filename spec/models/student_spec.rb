describe Student do
  it { should have_many :bank_accounts }
  it { should have_many :payment_methods }
  it { should have_many :credit_cards }
  it { should have_many :payments }
  it { should have_many :ratings }
  it { should have_many(:internships).through(:ratings) }
  it { should belong_to :plan }
  it { should have_many :attendance_records }
  it { should have_many(:courses).through(:enrollments) }
  it { should belong_to(:primary_payment_method).class_name('PaymentMethod') }
  it { should have_many :signatures }
  it { should have_many :interview_assignments }
  it { should have_one :internship_assignment }

  describe 'validations' do
    context 'validates plan_id when a student has accepted the epicenter invitation and created an account' do
      before { allow(subject).to receive(:invitation_accepted_at?).and_return(true) }
      it { should validate_presence_of :plan_id }
    end

    context 'does not validate plan_id when a student has not accepted the epicenter invitation' do
      before { allow(subject).to receive(:invitation_accepted_at?).and_return(false) }
      it { should_not validate_presence_of :plan_id }
    end
  end

  describe '#with_activated_accounts' do
    it 'returns all students who have activated their accounts' do
      inactive_student = FactoryGirl.create(:student, sign_in_count: 0)
      active_student = FactoryGirl.create(:student, sign_in_count: 4)
      expect(Student.with_activated_accounts).to eq [active_student]
    end
  end

  describe '#internship_course' do
    let(:internship_course) { FactoryGirl.create(:internship_course) }
    let(:non_internship_course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, courses: [internship_course, non_internship_course]) }

    it 'returns the internship course for a student' do
      expect(student.internship_course).to eq internship_course
    end
  end

  describe '#courses_withdrawn' do
    let!(:first_course) { FactoryGirl.create(:past_course) }
    let!(:second_course) { FactoryGirl.create(:course) }
    let!(:student) { FactoryGirl.create(:student, courses: [first_course, second_course]) }

    it 'returns courses student was withdrawn from' do
      FactoryGirl.create(:attendance_record, student: student, date: second_course.start_date)
      Enrollment.find_by(student: student, course: second_course).destroy
      student.reload
      expect(student.courses_withdrawn).to eq [second_course]
    end
  end

  describe '#courses_with_withdrawn' do
    let!(:first_course) { FactoryGirl.create(:past_course) }
    let!(:second_course) { FactoryGirl.create(:course) }
    let!(:student) { FactoryGirl.create(:student, courses: [first_course, second_course]) }

    it 'returns all courses, including withdrawn courses' do
      FactoryGirl.create(:attendance_record, student: student, date: second_course.start_date)
      Enrollment.find_by(student: student, course: second_course).destroy
      student.reload
      expect(student.courses_with_withdrawn).to eq [first_course, second_course]
    end
  end

  describe "#other_courses" do
    let!(:first_course) { FactoryGirl.create(:past_course) }
    let!(:second_course) { FactoryGirl.create(:course) }
    let!(:third_course) { FactoryGirl.create(:future_course) }
    let(:student) { FactoryGirl.create(:student, course: first_course) }

    it 'returns courses that a student is not enrolled in' do
      expect(student.other_courses).to eq [second_course, third_course]
    end
  end

  describe "#course" do
    let(:first_course) { FactoryGirl.create(:past_course) }
    let(:second_course) { FactoryGirl.create(:course) }
    let(:third_course) { FactoryGirl.create(:future_course) }
    let(:student) { FactoryGirl.create(:student, courses: [first_course, second_course, third_course]) }

    it 'returns the upcoming course when a student has enrolled, but class has not started' do
      travel_to first_course.start_date - 1 do
        expect(student.course).to eq first_course
      end
    end

    it 'returns the current course when class is in session' do
      travel_to first_course.start_date do
        expect(student.course).to eq first_course
      end
    end

    it 'returns the next course when a student is in between courses' do
      travel_to second_course.end_date + 1 do
        expect(student.course).to eq third_course
      end
    end

    it 'returns the last course when a student is no longer enrolled' do
      travel_to third_course.end_date + 1 do
        expect(student.course).to eq third_course
      end
    end
  end

  describe "#pair_on_day" do
    let(:course) { FactoryGirl.create(:course) }
    let(:student_1) { FactoryGirl.create(:student, course: course) }
    let(:student_2) { FactoryGirl.create(:student, course: course) }

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
    let!(:current_student) { FactoryGirl.create(:student) }
    let!(:student_2) { FactoryGirl.create(:user_with_score_of_9, course: current_student.course) }
    let!(:student_3) { FactoryGirl.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_4) { FactoryGirl.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_5) { FactoryGirl.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_6) { FactoryGirl.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_7_after_starting_point) { FactoryGirl.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_8) { FactoryGirl.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_9) { FactoryGirl.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_10_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_11_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_12_after_starting_point) { FactoryGirl.create(:user_with_score_of_6, course: current_student.course) }

    it "returns an empty array when there are no other students in a course", :stub_mailgun do
      student_without_classmates = FactoryGirl.create(:student)
      expect(student_without_classmates.random_pairs).to eq []
    end

    it "returns random pairs based on student total grade score for the most recent code review and distance_until_end is more than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:latest_total_grade_score).and_return(10)
      allow(current_student).to receive(:random_starting_point).and_return(1)
      expect(current_student.random_pairs).to eq [student_3, student_4, student_5, student_6, student_7_after_starting_point]
    end

    it "returns random pairs based on student total grade score for the most recent code review and distance_until_end is less than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:latest_total_grade_score).and_return(10)
      allow(current_student).to receive(:random_starting_point).and_return(5)
      expect(current_student.random_pairs).to eq [student_7_after_starting_point, student_2, student_3, student_4, student_5]
    end

    it "returns random pairs when the student total grade score is nil and distance_until_end is less than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:random_starting_point).and_return(8)
      expect(current_student.random_pairs).to eq [student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point, student_2, student_3]
    end

    it "returns random pairs when the student total grade score is nil and distance_until_end is more than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:random_starting_point).and_return(6)
      expect(current_student.random_pairs).to eq [student_8, student_9, student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point]
    end
  end

  describe "#latest_total_grade_score" do
    let(:student) { FactoryGirl.create(:student) }
    let(:submission) { FactoryGirl.create(:submission, student: student) }

    it 'returns nil when a student has not submitted a code review', :stub_mailgun do
      expect(student.latest_total_grade_score).to eq nil
    end

    it 'returns a total grade score for the latest code review when a student has received a grade', :stub_mailgun do
      FactoryGirl.create(:passing_review, student: student, submission: submission)
      expect(student.latest_total_grade_score).to eq 3
    end

    it 'returns an aggregate total grade score for the latest code review when a student has received multiple grades', :stub_mailgun do
      review = FactoryGirl.create(:passing_review, student: student, submission: submission)
      objective = FactoryGirl.create(:objective)
      FactoryGirl.create(:failing_grade, review: review, objective: objective )
      expect(student.latest_total_grade_score).to eq 4
    end
  end

  describe '#close_io_lead_exists?', :vcr do
    it 'returns true if the Close.io lead for the student exists' do
      student = FactoryGirl.create(:student, email: 'example@example.com')
      expect(student.close_io_lead_exists?).to eq true
    end

    it 'returns false if the Close.io lead for the student exists' do
      student = FactoryGirl.create(:student, email: 'wrong_email@test.com')
      expect(student.close_io_lead_exists?).to eq false
    end
  end

  describe "updating close.io when documents have been signed" do
    let(:student) { FactoryGirl.create(:student, email: 'example@example.com') }
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
      student.update_close_io({ status: "Enrolled", 'custom.Amount paid': student.total_paid / 100 })
    end

    it "fails to update the record when there are not enough signatures", :vcr do
      student.update(email: 'fake@fake.com')
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      allow(student).to receive(:total_paid).and_return(100)
      expect { student.update_close_io({ status: "Enrolled", 'custom.Amount paid': student.total_paid / 100 }) }.to raise_error(RuntimeError, 'The Close.io lead for fake@fake.com was not found.')
    end

    it "fails to update the record when no payment has been made", :vcr do
      student.update(email: 'fake@fake.com')
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      allow(student).to receive(:total_paid).and_return(0)
      expect { student.update_close_io({ status: "Enrolled", 'custom.Amount paid': student.total_paid / 100 }) }.to raise_error(RuntimeError, 'The Close.io lead for fake@fake.com was not found.')
    end
  end

  describe '#get_crm_status', :vcr do
    it 'returns lead status' do
      student = FactoryGirl.create(:student, email: 'example@example.com')
      expect(student.get_crm_status).to eq "Applicant - No longer interested (legacy)"
    end
  end

  describe 'updating close.io when student email is updated' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:contact_id) { close_io_client.list_leads('email:' + student.email).data.first.contacts.first.id }

    before do
      allow(student).to receive(:close_io_client).and_return(close_io_client)
    end

    it 'updates the record successfully', :vcr do
      allow(close_io_client).to receive(:update_contact).and_return({})
      old_entry = Hashie::Mash.new({ type: "office", email: student.email })
      new_entry = Hashie::Mash.new({ type: "office", email: "second-email@example.com" })
      expect(close_io_client).to receive(:update_contact).with(contact_id, { 'emails': [new_entry, old_entry] })
      student.update_close_email(new_entry.email)
    end

    it 'does not update the record when the email is not found', :vcr do
      student.update(email: "no_close_entry@example.com")
      expect { student.update_close_email("second-email@example.com") }.to raise_error(CrmError, 'The student record for no_close_entry@example.com was not found.')
    end

    it 'raises an error when the new email is invalid', :vcr do
      allow(close_io_client).to receive(:update_contact).and_return({"errors"=>[], "field-errors"=>{"emails"=>{"errors"=>{"0"=>{"errors"=>[], "field-errors"=>{"email"=>"Invalid email address."}}}}}})
      expect { student.update_close_email("invalid@inavlid") }.to raise_error(CrmError, 'Invalid email address.')
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
    let(:seattle_student) { FactoryGirl.create(:seattle_student) }

    it "returns true if all 3 main documents have been signed and demographics form submitted" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      student.update(demographics: true)
      expect(student.signed_main_documents?).to eq true
    end

    it "returns false if demographics form not submitted" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      expect(student.signed_main_documents?).to eq false
    end

    it "returns false if all 3 main documents have not been signed" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      student.update(demographics: true)
      expect(student.signed_main_documents?).to eq false
    end

    it "returns true if all 4 documents have been signed for a Seattle student and demographics form submitted" do
      FactoryGirl.create(:completed_code_of_conduct, student: seattle_student)
      FactoryGirl.create(:completed_refund_policy, student: seattle_student)
      FactoryGirl.create(:completed_complaint_disclosure, student: seattle_student)
      FactoryGirl.create(:completed_enrollment_agreement, student: seattle_student)
      seattle_student.update(demographics: true)
      expect(seattle_student.signed_main_documents?).to eq true
    end

    it "returns false if demographics form not submitted for a Seattle student" do
      FactoryGirl.create(:completed_code_of_conduct, student: seattle_student)
      FactoryGirl.create(:completed_refund_policy, student: seattle_student)
      FactoryGirl.create(:completed_complaint_disclosure, student: seattle_student)
      FactoryGirl.create(:completed_enrollment_agreement, student: seattle_student)
      expect(seattle_student.signed_main_documents?).to eq false
    end

    it "returns false if extra required Seattle document not signed" do
      FactoryGirl.create(:completed_code_of_conduct, student: seattle_student)
      FactoryGirl.create(:completed_refund_policy, student: seattle_student)
      FactoryGirl.create(:completed_enrollment_agreement, student: seattle_student)
      seattle_student.update(demographics: true)
      expect(seattle_student.signed_main_documents?).to eq false
    end
  end

  it "validates that the primary payment method belongs to the user", :stripe_mock do
    student = FactoryGirl.create(:student)
    other_students_credit_card = FactoryGirl.create(:credit_card)
    student.primary_payment_method = other_students_credit_card
    expect(student.valid?).to be false
  end

  describe "#stripe_customer", :stripe_mock do
    it "creates a Stripe Customer object for a student" do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns the Stripe Customer object" do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns a Stripe Customer object if one already exists" do
      student = FactoryGirl.create(:student)
      first_stripe_customer_return = student.stripe_customer
      second_stripe_customer_return = student.stripe_customer
      expect(first_stripe_customer_return.id).to eq second_stripe_customer_return.id
    end
  end

  describe "#stripe_customer_id", :stripe_mock do
    it "starts out nil" do
      student = FactoryGirl.create(:student)
      expect(student.stripe_customer_id).to be_nil
    end

    it "is populated when a Stripe Customer object is created" do
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

  describe "#upfront_payment_due?", :stripe_mock do
    let(:student) { FactoryGirl.create :user_with_credit_card, email: 'example@example.com' }

    it "is true if student has upfront payment and no payments have been made" do
      expect(student.upfront_payment_due?).to be true
    end

    it "is false if student has no upfront payment" do
      student.plan.upfront_amount = 0
      expect(student.upfront_payment_due?).to be false
    end

    it "is false if student has made any payments", :vcr, :stub_mailgun do
      FactoryGirl.create(:payment_with_credit_card, student: student)
      expect(student.upfront_payment_due?).to be false
    end
  end

  describe "#make_upfront_payment" do
    it "makes a payment for the upfront amount of the student's plan", :vcr, :stripe_mock, :stub_mailgun do
      student = FactoryGirl.create(:user_with_credit_card, email: 'example@example.com')
      student.make_upfront_payment
      expect(student.payments.first.amount).to eq student.plan.upfront_amount
    end
  end

  describe "#upfront_amount_with_fees" do
    it "calculates the total upfront amount", :stripe_mock do
      plan = FactoryGirl.create(:upfront_payment_only_plan, upfront_amount: 200_00)
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
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it 'returns false for a date before class starts' do
      travel_to course.start_date.to_date - 1.day do
        expect(student.class_in_session?).to eq false
      end
    end

    it 'returns false for a date after class ends' do
      travel_to course.end_date.to_date + 1.day do
        expect(student.class_in_session?).to eq false
      end
    end

    it 'returns true for a date during class' do
      travel_to course.start_date.to_date do
        expect(student.class_in_session?).to eq true
      end

      travel_to course.start_date.to_date + 2.weeks do
        expect(student.class_in_session?).to eq true
      end
    end
  end

  describe '#class_over?' do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it 'returns false before class is over' do
      travel_to course.end_date.to_date - 5.days do
        expect(student.class_over?).to eq false
      end
    end

    it 'returns true after class ends' do
      travel_to course.end_date.to_date + 1.day do
        expect(student.class_over?).to eq true
      end
    end
  end

  describe '#completed_internship_course?' do
    let(:internship_course) { FactoryGirl.create(:internship_course) }
    let(:student_with_internship_course) { FactoryGirl.create(:student, course: internship_course) }
    let(:student_without_internship_course) { FactoryGirl.create(:student) }

    it 'returns true when a student has completed an internship course' do
      travel_to internship_course.end_date + 1.day do
        expect(student_with_internship_course.completed_internship_course?).to eq true
      end
    end

    it 'returns false when a student has completed an internship course' do
      travel_to internship_course.end_date + 1.day do
        expect(student_without_internship_course.completed_internship_course?).to eq false
      end
    end
  end

  describe '#passed_all_code_reviews?', :stub_mailgun do
    let(:student) { FactoryGirl.create(:student) }
    let(:code_review) { FactoryGirl.create(:code_review, course: student.course) }
    let(:code_review_2) { FactoryGirl.create(:code_review, course: student.course) }
    let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }
    let(:submission_2) { FactoryGirl.create(:submission, code_review: code_review_2, student: student) }

    it 'true if all code reviews are passing' do
      FactoryGirl.create(:passing_review, submission: submission)
      FactoryGirl.create(:passing_review, submission: submission_2)
      expect(student.passed_all_code_reviews?).to eq(true)
    end

    it 'false if all code reviews are failing' do
      FactoryGirl.create(:failing_review, submission: submission)
      FactoryGirl.create(:failing_review, submission: submission_2)
      expect(student.passed_all_code_reviews?).to eq(false)
    end

    it 'false if any code reviews are failing' do
      FactoryGirl.create(:passing_review, submission: submission)
      FactoryGirl.create(:failing_review, submission: submission_2)
      expect(student.passed_all_code_reviews?).to eq(false)
    end

    it 'false if any code reviews are missing' do
      code_review_3 = FactoryGirl.create(:code_review, course: student.course)
      FactoryGirl.create(:passing_review, submission: submission)
      FactoryGirl.create(:passing_review, submission: submission_2)
      expect(student.passed_all_code_reviews?).to eq(false)
    end
  end

  describe '#submission_for' do
    let(:student) { FactoryGirl.create(:student) }
    let(:code_review_1) { FactoryGirl.create(:code_review, course: student.course) }
    let(:code_review_2) { FactoryGirl.create(:code_review, course: student.course) }
    let!(:submission_1) { FactoryGirl.create(:submission, student: student, code_review: code_review_1) }

    it 'returns a student submission for a particular code review' do
      expect(student.submission_for(code_review_1)).to eq submission_1
    end
  end

  describe '#attendance_score' do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it "calculates the student's attendance score" do
      day_one = student.course.start_date
      student.course.update(class_days: [day_one])

      travel_to day_one.beginning_of_day do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_one.end_of_day do
        expect(student.attendance_score(course)).to eq 50
      end
    end

    it "calculates the student attendance score with perfect attendance records" do
      day_one = student.course.start_date.in_time_zone(student.course.office.time_zone)
      student.course.update(class_days: [day_one])
      travel_to day_one.beginning_of_day + 8.hours do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to day_one.beginning_of_day + 17.hours do
        student.attendance_records.last.update({signing_out: true})
        expect(student.attendance_score(course)).to eq 100
      end
    end

    it "calculates the student attendance score with no attendance records" do
      expect(student.attendance_score(course)).to eq 0
    end
  end

  describe '#absences' do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it "calculates the number of absences" do
      day_one = student.course.start_date
      student.course.update(class_days: [day_one])

      travel_to day_one.beginning_of_day do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_one.end_of_day do
        expect(student.absences(course)).to eq 0.5
      end
    end

    it "calculates the number of absences before start of class on the next day" do
      day_one = student.course.start_date
      day_two = day_one + 1.day
      student.course.update(class_days: [day_one, day_two])

      travel_to day_one.beginning_of_day do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_two.beginning_of_day do
        expect(student.absences(course)).to eq 1.5
      end
    end

    it "calculates the number of absences with perfect attendance records" do
      day_one = student.course.start_date.in_time_zone(student.course.office.time_zone)
      student.course.update(class_days: [day_one])

      travel_to day_one.beginning_of_day + 8.hours do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to day_one.beginning_of_day + 17.hours do
        student.attendance_records.last.update({signing_out: true})
        expect(student.absences(course)).to eq 0
      end
    end
  end

  describe '#solos' do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it "calculates the number of solos when none" do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date + 2.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 2
    end

    it "calculates the number of solos when some" do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student, pair_id: 1)
      end
      travel_to course.start_date + 2.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end

    it "ignores solos when attendance record is marked ignore" do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student, ignore: true)
      end
      travel_to course.start_date + 2.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end

    it "ignores friday solos" do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date + 4.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end

    it "only counts within this course" do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date - 5.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end
  end

  describe '#attendance_records_for' do
    let(:course) { FactoryGirl.create(:course) }
    let(:past_course) { FactoryGirl.create(:past_course) }
    let(:future_course) { FactoryGirl.create(:future_course) }
    let(:internship_course) { FactoryGirl.create(:internship_course) }
    let(:student) { FactoryGirl.create(:student, course: course) }

    it 'counts the number of days the student has been on time to class' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours do
        attendance_record = FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 23.hours do
        student.attendance_records.last.update({:signing_out => true})
      end
      expect(student.attendance_records_for(:on_time)).to eq 1
    end

    it 'counts the number of days the student has been tardy' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 9.hours + 20.minutes do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 9.hours + 1.day do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.attendance_records_for(:tardy)).to eq 2
    end

    it 'counts the number of days the student has left early (failed to sign out)' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours + 55.minutes do
        attendance_record = FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 15.hours do
        student.attendance_records.last.update({:signing_out => true})
      end
      expect(student.attendance_records_for(:left_early)).to eq 1
    end

    it 'counts the number of days the student has been absent' do
      travel_to course.start_date do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to course.start_date + 2.days do
        FactoryGirl.create(:attendance_record, student: student)
      end
      expect(student.attendance_records_for(:absent)).to eq 23
    end

    context 'for a particular course' do
      it 'counts the number of days the student has been on time to class' do
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 5.days + 8.hours do
          attendance_record_outside_current_course_date_range = FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 5.days - 1.hour do
          student.attendance_records.last.update({ signing_out: true })
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours do
          attendance_record = FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 17.hours do
          student.attendance_records.last.update({ signing_out: true })
        end
        expect(student.attendance_records_for(:on_time, student.course)).to eq 1
      end

      it 'counts the number of days the student has been tardy' do
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 5.days + 9.hours + 10.minutes do
          FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 4.days + 9.hours + 10.minutes do
          FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 9.hours + 20.minutes do
          FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 1.day + 9.hours + 20.minutes do
          FactoryGirl.create(:attendance_record, student: student)
          expect(student.attendance_records_for(:tardy, student.course)).to eq 2
        end
      end

      it 'counts the number of days the student has left early (failed to sign out)' do
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 5.days + 8.hours + 55.minutes do
          attendance_record_outside_current_course_date_range = FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) - 5.days + 15.hours + 55.minutes do
          student.attendance_records.last.update({ signing_out: true })
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours + 55.minutes do
          attendance_record = FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date.in_time_zone(course.office.time_zone) + 15.hours + 55.minutes do
          student.attendance_records.last.update({ signing_out: true })
        end
        expect(student.attendance_records_for(:left_early, student.course)).to eq 1
      end

      it 'counts the number of days the student has been absent' do
        travel_to course.start_date - 5 do
          travel 1.day
          FactoryGirl.create(:attendance_record, student: student)
        end
        travel_to course.start_date do
          travel 1.day
          FactoryGirl.create(:attendance_record, student: student)
          expect(student.attendance_records_for(:absent, student.course)).to eq 1
        end
      end
    end

    context 'for a particular range of courses' do
      before do
        allow_any_instance_of(Student).to receive(:update_close_io)
        student.courses = [past_course, course, future_course]
        student.courses.each do |c|
          create_attendance_record_in_course(c, "on_time")
          create_attendance_record_in_course(c, "tardy")
          create_attendance_record_in_course(c, "left_early")
        end
      end

      it 'counts the number of days the student has been on time to class' do
        expect(student.attendance_records_for(:on_time, course, future_course)).to eq 2
      end

      it 'counts the number of days the student has been tardy' do
        expect(student.attendance_records_for(:tardy, past_course, course)).to eq 2
      end

      it 'counts the number of days the student has left early (failed to sign out)' do
        expect(student.attendance_records_for(:left_early, past_course, future_course)).to eq 3
      end

      it 'counts the number of days the student has been absent' do
        attended = past_course.total_class_days + course.total_class_days + future_course.total_class_days - AttendanceRecord.count
        expect(student.attendance_records_for(:absent, past_course, future_course)).to eq attended
      end
    end
  end

  describe '#total_paid', :vcr, :stripe_mock, :stub_mailgun do
    it 'sums all of the students payments' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'example@example.com')
      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 200_00)
      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 200_00)
      expect(student.total_paid).to eq 400_00
    end

    it 'does not include failed payments' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'example@example.com')
      FactoryGirl.create(:payment_with_credit_card, student: student, amount: 200_00)
      failed_payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 200_00)
      failed_payment.update(status: 'failed')
      expect(student.total_paid).to eq 200_00
    end

    it 'subtracts refunds' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: 200_00, offline: true)
      payment.update(refund_amount: 5000)
      expect(student.total_paid).to eq 150_00
    end

    it 'includes negative offline transactions' do
      student = FactoryGirl.create(:user_with_credit_card, email: 'example@example.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student, amount: -200_00, offline: true)
      expect(student.total_paid).to eq -200_00
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

  describe "abilities" do
    let(:student) { FactoryGirl.create(:student) }
    subject { Ability.new(student, "::1") }

    context 'for code reviews' do
      it { is_expected.to have_abilities(:read, CodeReview.new(course: student.course)) }
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

    context 'for bank_accounts' do
      it { is_expected.to have_abilities(:create, BankAccount.new) }
    end

    context 'for credit_cards' do
      it { is_expected.to have_abilities(:create, CreditCard.new) }
    end

    context 'for payments' do
      let(:bank_account) { FactoryGirl.create(:bank_account, student: student) }
      let(:credit_card) { FactoryGirl.create(:credit_card, student: student) }

      it 'allows students to create payments using one of their payment methods', :vcr do
        is_expected.to have_abilities(:create, Payment.new(payment_method: bank_account, student_id: student.id))
        is_expected.to have_abilities(:create, Payment.new(payment_method: credit_card, student_id: student.id))
      end

      it "doesn't allow students to create payments for others' payment methods", :vcr do
        another_bank_account = FactoryGirl.create(:bank_account)
        another_credit_card = FactoryGirl.create(:credit_card)
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_bank_account))
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_credit_card))
      end

      it "doesn't allow students to create payments for other students", :stripe_mock do
        another_student = FactoryGirl.create(:student)
        is_expected.to not_have_abilities(:create, Payment.new(student: another_student, payment_method: credit_card))
      end

      it "doesn't allow students to create payments without a specified student", :stripe_mock do
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: credit_card))
      end

      it { is_expected.to have_abilities(:read, Payment.new(student: student)) }
      it { is_expected.to not_have_abilities(:read, Payment.new) }
    end

    context 'for companies' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Company.new)}
    end

    context 'for internships' do
      before do
        allow_any_instance_of(Student).to receive(:update_close_io)
        student.enrollments.destroy_all
        student.course = FactoryGirl.create(:internship_course)
      end
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], Internship.new)}
      it { is_expected.to have_abilities(:read, Internship.new(courses: [student.course])) }
    end

    context 'for students' do
      it { is_expected.to not_have_abilities(:read, Student.new) }
      it { is_expected.to have_abilities(:read, student) }
    end

    context 'for transcripts' do
      it { is_expected.to have_abilities(:read, Transcript) }
    end
  end

  describe '.pull_info_from_crm', :vcr do
    context 'for part-time students' do
      it 'returns name & course id for part-time CRM lead given email' do
        course = FactoryGirl.create(:part_time_course, class_days: [Date.parse('2000-01-03')], office: FactoryGirl.create(:philadelphia_office))
        expect(Student.pull_info_from_crm("example-part-time@example.com")).to eq({name: "THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.", course_id: course.id, errors: []})
      end

      it 'returns error if course not found in Epicenter' do
        expect(Student.pull_info_from_crm("example-part-time@example.com")[:errors]).to include "Course not found in Epicenter"
      end
    end

    context 'for full-time students where cohort does not exist' do
      it 'returns error if cohort not found in Epicenter' do
        expect(Student.pull_info_from_crm("example@example.com")[:errors]).to include "Course not found in Epicenter"
        expect(Student.pull_info_from_crm("example@example.com")[:errors]).to include "Cohort not found in Epicenter"
      end
    end

    context 'for full-time students where course does exist in Epiceter' do
      let!(:cohort) { FactoryGirl.create(:cohort, start_date: Date.parse('2000-01-03')) }

      it 'returns name, cohort id & course id for full-time CRM lead given email' do
        expect(Student.pull_info_from_crm("example@example.com")).to eq({name: "THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.", cohort_id: cohort.id, course_id: cohort.courses.first.id, errors: []})
      end

      it 'returns error if user already exists in Epicenter' do
        FactoryGirl.create(:user_with_all_documents_signed, email: "example@example.com")
        expect(Student.pull_info_from_crm("example@example.com")[:errors]).to include "Email already used in Epicenter"
      end

      it 'returns error if email not found in Close' do
        expect(Student.pull_info_from_crm("email_not_in_close@example.com")[:errors]).to include "Email not found in CRM"
      end

      it 'returns error if name not listed in Close lead' do
        expect(Student.pull_info_from_crm("automated_testing_no_name@example.com")[:errors]).to include "Name not found in CRM"
      end

      it 'returns error if what class are you interested in field is blank in Close lead' do
        expect(Student.pull_info_from_crm("automated_testing_no_name@example.com")[:errors]).to include "What class are you interested in not found in CRM"
      end
    end
  end

  describe 'valid_plans' do
    let!(:rate_plan_2016) { FactoryGirl.create(:rate_plan_2016) }
    let!(:rate_plan_2017) { FactoryGirl.create(:rate_plan_2017) }
    let!(:rate_plan_2018) { FactoryGirl.create(:rate_plan_2018) }
    let!(:pt_plan_2016) { FactoryGirl.create(:parttime_plan_2016) }
    let!(:pt_plan_2017) { FactoryGirl.create(:parttime_plan_2017) }
    let!(:pt_plan_2018) { FactoryGirl.create(:parttime_plan) }

    it 'lists valid plans for full-time student with 2016 rates' do
      course = FactoryGirl.create(:course, class_days: [Time.new(2016, 12, 1).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [rate_plan_2016]
    end

    it 'lists valid plans for full-time student with 2017 rates' do
      course = FactoryGirl.create(:course, class_days: [Time.new(2017, 6, 1).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [rate_plan_2017]
    end

    it 'lists valid plans for full-time student with 2018 rates' do
      course = FactoryGirl.create(:course, class_days: [Time.new(2017, 10, 2).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [rate_plan_2018]
    end

    it 'lists valid plans for part-time student with 2016 rates' do
      course = FactoryGirl.create(:part_time_course, class_days: [Time.new(2016, 12, 1).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [pt_plan_2016]
    end

    it 'lists valid plans for part-time student with 2017 rates' do
      course = FactoryGirl.create(:part_time_course, class_days: [Time.new(2017, 6, 1).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [pt_plan_2017]
    end

    it 'lists valid plans for part-time student with 2018 rates' do
      course = FactoryGirl.create(:part_time_course, class_days: [Time.new(2017, 10, 2).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [course])
      expect(student.valid_plans).to eq [pt_plan_2018]
    end

    it 'lists valid plans for full-time student who started in 2016 rates but currently in later class' do
      first_course = FactoryGirl.create(:course, class_days: [Time.new(2017, 5, 15).to_date])
      current_course = FactoryGirl.create(:course, class_days: [Time.new(2017, 6, 19).to_date])
      student = FactoryGirl.create(:student, plan_id: nil, courses: [first_course, current_course])
      travel_to current_course.start_date do
        expect(student.valid_plans).to eq [rate_plan_2016]
      end
    end
  end

  describe 'validate_plan_id' do
    let(:course) { FactoryGirl.create(:course, class_days: [Time.new(2016, 12, 1).to_date]) }
    let(:plan) { FactoryGirl.create(:rate_plan_2016) }
    let(:student) { FactoryGirl.create(:student, plan_id: nil, courses: [course]) }

    it 'triggers validate_plan_id on update' do
      expect(student).to receive(:validate_plan_id)
      student.update(plan_id: plan.id)
    end

    it 'validates plan is an option for course' do
      expect(student.update(plan_id: plan.id)).to be(true)
    end

    it 'validates plan is not an option for course' do
      plan.update(parttime: true)
      expect(student.update(plan_id: plan.id)).to be(false)
    end
  end

  describe 'update_starting_cohort_crm' do
    let(:student) { FactoryGirl.create(:student) }
    let(:other_course) { FactoryGirl.create(:course) }

    before do
      allow(student).to receive(:update_close_io)
    end

    it 'triggers update_starting_cohort_crm on update' do
      expect(student).to receive(:update_starting_cohort_crm)
      student.update(starting_cohort_id: other_course.id)
    end

    it 'updates CRM on change to starting_cohort_id' do
      expect(student).to receive(:update_close_io).with({ 'custom.Starting Cohort': student.course.description })
      student.update(starting_cohort_id: other_course.id)
    end

    it 'clears CRM starting cohort field if starting_cohort_id is set to nil' do
      student.update_columns(starting_cohort_id: student.course.id)
      expect(student).to receive(:update_close_io).with({ 'custom.Starting Cohort': nil })
      student.update(starting_cohort_id: nil)
    end

    it 'does not trigger update_starting_cohort_crm when starting_cohort_id not changed' do
      student.update_columns(starting_cohort_id: student.course.id)
      expect(student).to_not receive(:update_starting_cohort_crm)
      student.update(starting_cohort_id: student.course.id)
    end
  end

  describe 'paranoia' do
    it 'archives destroyed user' do
      student = FactoryGirl.create(:student)
      student.destroy
      expect(Student.count).to eq 0
      expect(Student.with_deleted.count).to eq 1
    end

    it 'restores archived user' do
      student = FactoryGirl.create(:student)
      student.destroy
      student.restore
      expect(Student.count).to eq 1
    end
  end

  describe 'get_status' do
    let(:student) { FactoryGirl.create(:student) }

    before { allow(student).to receive(:update_close_io) }

    it 'reports status when student is archived' do
      student.destroy
      expect(Student.with_deleted.find(student.id).get_status).to eq 'Archived'
    end

    it 'reports status when no enrolled or withdrawn courses' do
      student.enrollments.first.destroy
      expect(student.get_status).to eq 'Not enrolled'
    end

    it 'reports status of current student' do
      expect(student.get_status).to eq 'Current student'
    end

    it 'reports status of future student' do
      student.courses = [FactoryGirl.create(:future_course)]
      expect(student.get_status).to eq 'Future student'
    end

    it 'reports status of graduated student' do
      student.courses = [FactoryGirl.create(:internship_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Graduate'
    end

    it 'reports status of student who finished before 2016' do
      student.courses = [FactoryGirl.create(:internship_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Graduate'
    end

    it 'reports status of student who withdrew (class over without completed internship course)' do
      student.courses = [FactoryGirl.create(:course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Incomplete'
    end

    it 'reports status of student who withdrew (withdrawn enrollments only)' do
      student.courses = [FactoryGirl.create(:course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      FactoryGirl.create(:attendance_record, student: student, date: student.course.start_date)
      Enrollment.find_by(student: student).destroy
      expect(student.get_status).to eq 'Incomplete'
    end

    it 'reports status of past part-time student' do
      student.courses = [FactoryGirl.create(:part_time_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Part-time (past)'
    end

    it 'reports status of current part-time student' do
      student.courses = [FactoryGirl.create(:part_time_course)]
      expect(student.get_status).to eq 'Part-time (current)'
    end

    it 'reports status of future part-time student' do
      student.courses = [FactoryGirl.create(:part_time_course, class_days: [(Time.zone.now.to_date + 5.weeks).monday])]
      expect(student.get_status).to eq 'Part-time (future)'
    end
  end
end

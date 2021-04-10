describe Student do
  it { should have_many :bank_accounts }
  it { should have_many :payment_methods }
  it { should have_many :credit_cards }
  it { should have_many :payments }
  it { should have_many :ratings }
  it { should have_many(:internships).through(:ratings) }
  it { should belong_to(:plan).optional }
  it { should have_many :attendance_records }
  it { should have_many(:courses).through(:enrollments) }
  it { should belong_to(:primary_payment_method).class_name('PaymentMethod').optional }
  it { should have_many :signatures }
  it { should have_many :interview_assignments }
  it { should have_one :internship_assignment }
  it { should have_many :cost_adjustments }
  it { should have_many :daily_submissions }
  it { should have_many(:evaluations_of_peers).class_name('PeerEvaluation').with_foreign_key(:evaluator) }
  it { should have_many(:evaluations_by_peers).class_name('PeerEvaluation').with_foreign_key(:evaluatee) }
  it { should have_many(:evaluations_of_pairs).class_name('PairFeedback').with_foreign_key(:student) }
  it { should have_many(:evaluations_by_pairs).class_name('PairFeedback').with_foreign_key(:pair) }

  describe 'validations' do
    context 'does not validate plan_id when a student has not accepted the epicenter invitation' do
      before { allow(subject).to receive(:invitation_accepted_at?).and_return(false) }
      it { should_not validate_presence_of :plan_id }
    end
  end

  describe 'sets payment plan before_create' do
    it 'does not set payment plan for fulltime students' do
      student = FactoryBot.build(:student, plan_id: nil)
      student.save
      expect(student.plan).to eq nil
    end

    it 'sets Fidgetech students to special $0 payment plan' do
      special_plan = FactoryBot.create(:special_plan)
      course = FactoryBot.create(:course, description: 'Fidgetech')
      student = FactoryBot.build(:student, plan_id: nil, courses: [course])
      student.save
      expect(student.plan).to eq special_plan
    end

    it 'sets parttime intro students to parttime plan' do
      parttime_plan = FactoryBot.create(:parttime_plan)
      course = FactoryBot.create(:part_time_course, track: FactoryBot.create(:part_time_track))
      student = FactoryBot.build(:student, plan_id: nil, courses: [course])
      student.save
      expect(student.plan).to eq parttime_plan
    end

    it 'does not set payment plan for part-time full-stack students' do
      parttime_plan = FactoryBot.create(:parttime_plan)
      cohort = FactoryBot.create(:part_time_c_react_cohort)
      student = FactoryBot.build(:student, plan_id: nil, courses: cohort.courses)
      student.save
      expect(student.plan).to eq nil
    end

    it 'does not change payment plan if one already assigned' do
      standard_plan = FactoryBot.create(:standard_plan)
      student = FactoryBot.build(:student, plan: standard_plan)
      student.save
      expect(student.plan).to eq standard_plan
    end
  end

  describe 'updates payment plan in Close', :dont_stub_crm, :vcr do

    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { ENV['EXAMPLE_CRM_LEAD_ID'] }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'does not update in Close when fulltime student created' do
      plan = FactoryBot.create(:upfront_plan)
      course = FactoryBot.create(:course)
      student = FactoryBot.build(:student, email: 'example@example.com', plan: nil, courses: [course])
      expect(CrmUpdateJob).to_not receive(:perform_later)
      student.save
    end

    it 'updates in Close when parttime student created' do
      plan = FactoryBot.create(:parttime_plan)
      course = FactoryBot.create(:part_time_course, track: FactoryBot.create(:part_time_track))
      student = FactoryBot.build(:student, email: 'example@example.com', plan: nil, courses: [course])
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => plan.close_io_description })
      student.save
    end

    it 'updates in Close when Fidgetech student created' do
      plan = FactoryBot.create(:special_plan)
      course = FactoryBot.create(:course, description: 'Fidgetech')
      student = FactoryBot.build(:student, email: 'example@example.com', plan: nil, courses: [course])
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => plan.close_io_description })
      student.save
    end

    it 'updates in Close when plan_id changed' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      new_plan = FactoryBot.create(:loan_plan)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => new_plan.close_io_description })
      student.update(plan: new_plan)
    end

    it 'does not update in Close when plan_id not changed' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to_not receive(:perform_later)
      student.update(name: 'foo')
    end
  end

  describe 'updates probation in Close', :dont_stub_crm, :vcr do

    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { ENV['EXAMPLE_CRM_LEAD_ID'] }

    before do
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
    end

    it 'updates teacher probation in Close when set' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PROBATION_ADVISOR'] => nil, Rails.application.config.x.crm_fields['PROBATION_TEACHER'] => 'Yes' })
      student.update(probation_teacher: true)
    end

    it 'clears teacher probation in Close when unset' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PROBATION_ADVISOR'] => nil, Rails.application.config.x.crm_fields['PROBATION_TEACHER'] => nil })
      student.update(probation_teacher: false)
    end

    it 'updates advisor probation in Close when set' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PROBATION_ADVISOR'] => 'Yes', Rails.application.config.x.crm_fields['PROBATION_TEACHER'] => nil })
      student.update(probation_advisor: true)
    end

    it 'clears advisor probation in Close when unset' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['PROBATION_ADVISOR'] => nil, Rails.application.config.x.crm_fields['PROBATION_TEACHER'] => nil })
      student.update(probation_advisor: false)
    end

    it 'does not update in Close when probation not changed' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to_not receive(:perform_later)
      student.update(name: 'foo')
    end
  end

  describe 'notifies teacher and advisor on probation count' do
    let(:course) { FactoryBot.create(:course, admin: FactoryBot.create(:admin)) }
    let(:student) { FactoryBot.create(:student, courses: [course]) }

    before do
      allow(EmailJob).to receive(:perform_later).and_return({})
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
    end

    it 'emails teacher when total probation count >= 3' do
      student.update(probation_teacher_count: 3, probation_advisor_count: 1)
      expect(EmailJob).to have_received(:perform_later).with(
        { :from => ENV['FROM_EMAIL_REVIEW'],
          :to => student.course.admin.email,
          :subject => "#{student.name} unmet requirements count total: 4",
          :text => "#{student.name} unmet requirements counts: 1 (advisor), 3 (teacher)"
        })
    end

    it 'creates CRM task when total probation count >= 3' do
      expect_any_instance_of(Closeio::Client).to receive(:create_task)
      student.update(probation_teacher_count: 1, probation_advisor_count: 2)
    end

    it 'does not email teacher or create CRM task when total probation count < 3' do
      expect_any_instance_of(Closeio::Client).to_not receive(:create_task)
      student.update(probation_teacher_count: 2, probation_advisor_count: 0)
      expect(EmailJob).to_not have_received(:perform_later)
    end
  end

  describe 'updates ending_cohort' do
    let(:student) { FactoryBot.create(:student, courses: []) }
    let(:cohort)  { FactoryBot.create(:cohort_with_internship) }

    it 'when current cohort changed' do
      student.update(cohort: cohort)
      expect(student.ending_cohort).to eq cohort
    end
  end

  describe '#with_activated_accounts' do
    it 'returns all students who have activated their accounts' do
      inactive_student = FactoryBot.create(:student, sign_in_count: 0)
      active_student = FactoryBot.create(:student, sign_in_count: 4)
      expect(Student.with_activated_accounts).to eq [active_student]
    end
  end

  describe '#internship_course' do
    let!(:internship_course) { FactoryBot.create(:internship_course) }
    let!(:non_internship_course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, courses: [internship_course, non_internship_course]) }

    it 'returns the internship course for a student' do
      expect(student.internship_course).to eq internship_course
    end
  end

  describe '#courses_withdrawn' do
    let!(:first_course) { FactoryBot.create(:past_course) }
    let!(:second_course) { FactoryBot.create(:midway_course) }
    let!(:student) { FactoryBot.create(:student, courses: [first_course, second_course]) }

    it 'returns courses student was withdrawn from' do
      FactoryBot.create(:attendance_record, student: student, date: second_course.start_date)
      Enrollment.find_by(student: student, course: second_course).destroy
      student.reload
      expect(student.courses_withdrawn).to eq [second_course]
    end
  end

  describe '#courses_with_withdrawn' do
    let!(:first_course) { FactoryBot.create(:past_course) }
    let!(:second_course) { FactoryBot.create(:midway_course) }
    let!(:student) { FactoryBot.create(:student, courses: [first_course, second_course]) }

    it 'returns all courses, including withdrawn courses' do
      FactoryBot.create(:attendance_record, student: student, date: second_course.start_date)
      Enrollment.find_by(student: student, course: second_course).destroy
      student.reload
      expect(student.courses_with_withdrawn).to eq [first_course, second_course]
    end
  end

  describe "#other_courses" do
    let!(:first_course) { FactoryBot.create(:past_course) }
    let!(:second_course) { FactoryBot.create(:course) }
    let!(:third_course) { FactoryBot.create(:future_course) }
    let(:student) { FactoryBot.create(:student, course: first_course) }

    it 'returns courses that a student is not enrolled in' do
      expect(student.other_courses).to eq [second_course, third_course]
    end
  end

  describe "#course" do
    let!(:first_course) { FactoryBot.create(:past_course) }
    let!(:second_course) { FactoryBot.create(:course) }
    let!(:third_course) { FactoryBot.create(:future_course) }
    let(:student) { FactoryBot.create(:student, courses: [first_course, second_course, third_course]) }

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

  describe "#pairs_on_day" do
    let(:course) { FactoryBot.create(:course) }
    let(:student_1) { FactoryBot.create(:student, course: course) }
    let(:student_2) { FactoryBot.create(:student, course: course) }

    it "returns the pair partner" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_1.pairs_on_day(attendance_record.date)).to eq [student_2]
    end

    it "returns empty array if a student has no pair for the day" do
      attendance_record_1 = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date)
      expect(student_1.pairs_on_day(attendance_record_1.date)).to eq []
    end

    it "returns two pairs if present" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [{pair_id: student_1.id}, {pair_id: student_2.id}])
      expect(student_1.pairs_on_day(attendance_record.date)).to include student_1
      expect(student_1.pairs_on_day(attendance_record.date)).to include student_2
    end
  end

  describe "#pairs_today" do
    it 'calls pairs_on_day with today date' do
      student = FactoryBot.create(:student)
      expect(student).to receive(:pairs_on_day).with(Time.zone.now.to_date)
      student.pairs_today
    end
  end

  describe "#inverse_pairs_on_day" do
    let(:course) { FactoryBot.create(:course) }
    let(:student_1) { FactoryBot.create(:student, course: course) }
    let(:student_2) { FactoryBot.create(:student, course: course) }

    it "returns student who marked them as a partner" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_2.inverse_pairs_on_day(attendance_record.date)).to eq [student_1]
    end

    it "returns empty array if no student marked them as a partner" do
      attendance_record_1 = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date)
      expect(student_2.inverse_pairs_on_day(attendance_record_1.date)).to eq []
    end

    it "returns two students that marked them as a partner" do
      student_3 = FactoryBot.create(:student, course: course)
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_3.id])
      attendance_record = FactoryBot.create(:attendance_record, student: student_2, date: student_1.course.start_date, pairings_attributes: [pair_id: student_3.id])
      expect(student_3.inverse_pairs_on_day(attendance_record.date)).to include student_1
      expect(student_3.inverse_pairs_on_day(attendance_record.date)).to include student_2
    end
  end

  describe "#inverse_pairs_today" do
    it 'calls invesre_pairs_on_day with today date' do
      student = FactoryBot.create(:student)
      expect(student).to receive(:inverse_pairs_on_day).with(Time.zone.now.to_date)
      student.inverse_pairs_today
    end
  end

  describe "#orphan_pairs_on_day" do
    let(:course) { FactoryBot.create(:course) }
    let(:student_1) { FactoryBot.create(:student, course: course) }
    let(:student_2) { FactoryBot.create(:student, course: course) }

    it "returns students claimed as extra pairs" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_1.orphan_pairs_on_day(attendance_record.date)).to eq [student_2]
    end

    it "returns empty array if reciprocated pairing" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      FactoryBot.create(:attendance_record, student: student_2, date: student_1.course.start_date, pairings_attributes: [pair_id: student_1.id])
      expect(student_2.orphan_pairs_on_day(attendance_record.date)).to eq []
    end

    it "actually checks they're claimed by the same person they claimed" do
      student_3 = FactoryBot.create(:student, course: course)
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      attendance_record = FactoryBot.create(:attendance_record, student: student_3, date: student_1.course.start_date, pairings_attributes: [pair_id: student_1.id])
      expect(student_1.orphan_pairs_on_day(attendance_record.date)).to eq [student_2]
    end
  end

  describe "#orphan_pairs_today" do
    it 'calls orphan_pairs_on_day with today date' do
      student = FactoryBot.create(:student)
      expect(student).to receive(:orphan_pairs_on_day).with(Time.zone.now.to_date)
      student.orphan_pairs_today
    end
  end

  describe "#inverse_orphan_pairs_on_day" do
    let(:course) { FactoryBot.create(:course) }
    let(:student_1) { FactoryBot.create(:student, course: course) }
    let(:student_2) { FactoryBot.create(:student, course: course) }

    it "returns student who marked them as a partner nonreciprocated" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_2.inverse_orphan_pairs_on_day(attendance_record.date)).to eq [student_1]
    end

    it "returns empty array if reciprocated pairing" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      FactoryBot.create(:attendance_record, student: student_2, date: student_1.course.start_date, pairings_attributes: [pair_id: student_1.id])
      expect(student_2.inverse_orphan_pairs_on_day(attendance_record.date)).to eq []
    end
  end

  describe "#inverse_orphan_pairs_today" do
    it 'calls inverse_orphan_pairs_on_day with today date' do
      student = FactoryBot.create(:student)
      expect(student).to receive(:inverse_orphan_pairs_on_day).with(Time.zone.now.to_date)
      student.inverse_orphan_pairs_today
    end
  end

  describe "#pairs_without_feedback_today" do
    let(:course) { FactoryBot.create(:course) }
    let(:student_1) { FactoryBot.create(:student, course: course) }
    let(:student_2) { FactoryBot.create(:student, course: course) }

    it "when no feedback done" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        expect(student_1.pairs_without_feedback_today).to eq [student_2]
      end
    end

    it "when all feedback done" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        FactoryBot.create(:pair_feedback, student: student_1, pair: student_2)
        expect(student_1.pairs_without_feedback_today).to eq []
      end
    end

    it "ignores feedback from a previous day" do
      travel_to course.start_date do
        FactoryBot.create(:pair_feedback, student: student_1, pair: student_2)
      end
      travel_to course.end_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        expect(student_1.pairs_without_feedback_today).to eq [student_2]
      end
    end

    it "ignores feedback from a different student" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        FactoryBot.create(:pair_feedback, pair: student_2)
        expect(student_1.pairs_without_feedback_today).to eq [student_2]
      end
    end

    it "ignores feedback for a different pair" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        FactoryBot.create(:pair_feedback, student: student_1)
        expect(student_1.pairs_without_feedback_today).to eq [student_2]
      end
    end

    it "when multiple pairs without feedback remaining" do
      student_3 = FactoryBot.create(:student)
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [{pair_id: student_2.id}, {pair_id: student_3.id}])
        expect(student_1.pairs_without_feedback_today).to include student_2
        expect(student_1.pairs_without_feedback_today).to include student_3
      end
    end

    it "does not include nonreciprocated pair" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student_1, date: Time.zone.now.to_date, pairings_attributes: [pair_id: student_2.id])
        expect(student_2.pairs_without_feedback_today).to eq []
      end
    end
  end

  describe "#attendance_record_on_day" do
    let(:student) { FactoryBot.create(:student) }
    let(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }

    it "returns the student's attendance record for the specified day" do
      expect(student.attendance_record_on_day(attendance_record.date)).to eq attendance_record
    end
  end

  describe "#random_pairs" do
    let!(:current_student) { FactoryBot.create(:student) }
    let!(:student_2) { FactoryBot.create(:user_with_score_of_9, course: current_student.course) }
    let!(:student_3) { FactoryBot.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_4) { FactoryBot.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_5) { FactoryBot.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_6) { FactoryBot.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_7_after_starting_point) { FactoryBot.create(:user_with_score_of_10, course: current_student.course) }
    let!(:student_8) { FactoryBot.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_9) { FactoryBot.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_10_after_starting_point) { FactoryBot.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_11_after_starting_point) { FactoryBot.create(:user_with_score_of_6, course: current_student.course) }
    let!(:student_12_after_starting_point) { FactoryBot.create(:user_with_score_of_6, course: current_student.course) }

    it "returns an empty array when there are no other students in a course", :stub_mailgun do
      student_without_classmates = FactoryBot.create(:student)
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

    xit "returns random pairs when the student total grade score is nil and distance_until_end is less than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:random_starting_point).and_return(8)
      expect(current_student.random_pairs).to eq [student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point, student_2, student_3]
    end

    it "returns random pairs when the student total grade score is nil and distance_until_end is more than the number of pairs", :stub_mailgun do
      allow(current_student).to receive(:random_starting_point).and_return(6)
      expect(current_student.random_pairs).to eq [student_8, student_9, student_10_after_starting_point, student_11_after_starting_point, student_12_after_starting_point]
    end
  end

  describe "#pair_ids" do
    let(:course) { FactoryBot.create(:course) }
    let!(:student_1) { FactoryBot.create(:student, course: course) }
    let!(:student_2) { FactoryBot.create(:student, course: course) }

    it "returns list of all pair ids" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_1.pair_ids).to eq [student_2.id]
    end

    it "includes pair ids from multiple attendance records without duplicates" do
      student_3 = FactoryBot.create(:student, course: course)
      student_4 = FactoryBot.create(:student, course: course)
      FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date + 1.day, pairings_attributes: [pair_id: student_3.id])
      FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date + 2.days, pairings_attributes: [{pair_id: student_3.id}, {pair_id: student_4.id}])
      expect(student_1.pair_ids.count).to eq 3
      expect(student_1.pair_ids).to include student_2.id
      expect(student_1.pair_ids).to include student_3.id
      expect(student_1.pair_ids).to include student_4.id
    end

    it "returns list of all pair ids for a given course time period" do
      attendance_record = FactoryBot.create(:attendance_record, student: student_1, date: student_1.course.start_date, pairings_attributes: [pair_id: student_2.id])
      expect(student_1.pair_ids(student_1.course)).to eq [student_2.id]
    end
  end

  describe "#solos" do
    let(:cohort) { FactoryBot.create(:part_time_cohort) }
    let(:past_cohort) { FactoryBot.create(:part_time_cohort, start_date: (cohort.start_date - 1.year).beginning_of_week) }
    let(:student) { FactoryBot.create(:student_without_courses) }
    let(:pair) { FactoryBot.create(:student_without_courses) }

    before { student.courses = [past_cohort.courses.first, cohort.courses.first] }

    it "with pair" do
      travel_to cohort.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
        expect(student.solos).to eq 0
      end
    end

    it "ignores solos outside current cohort" do
      FactoryBot.create(:attendance_record, student: student, date: past_cohort.start_date)
      travel_to cohort.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
        expect(student.solos).to eq 0
      end
    end

    it "without pair" do
      travel_to cohort.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        expect(student.solos).to eq 1
      end
    end
  end

  describe "#latest_total_grade_score" do
    let(:student) { FactoryBot.create(:student) }
    let(:submission) { FactoryBot.create(:submission, student: student) }

    it 'returns nil when a student has not submitted a code review', :stub_mailgun do
      expect(student.latest_total_grade_score).to eq nil
    end

    it 'returns a total grade score for the latest code review when a student has received a grade', :stub_mailgun do
      FactoryBot.create(:passing_review, student: student, submission: submission)
      expect(student.latest_total_grade_score).to eq 3
    end

    it 'returns an aggregate total grade score for the latest code review when a student has received multiple grades', :stub_mailgun do
      review = FactoryBot.create(:passing_review, student: student, submission: submission)
      objective = FactoryBot.create(:objective)
      FactoryBot.create(:failing_grade, review: review, objective: objective )
      expect(student.latest_total_grade_score).to eq 4
    end
  end

  describe "#crm_lead" do
    let(:student) { FactoryBot.create(:student) }

    it 'returns the CrmLead for the student' do
      expect(student.crm_lead).to be_instance_of(CrmLead)
    end
  end

  describe "#signed?" do
    let(:student) { FactoryBot.create(:student) }

    it "returns true if a signature has been signed" do
      FactoryBot.create(:completed_code_of_conduct, student: student)
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
    let(:student) { FactoryBot.create(:student) }
    let(:seattle_student) { FactoryBot.create(:seattle_student) }

    it "returns true if all 3 main documents have been signed and demographics form submitted" do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.update(demographics: true)
      expect(student.signed_main_documents?).to eq true
    end

    it "returns false if demographics form not submitted" do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      expect(student.signed_main_documents?).to eq false
    end

    it "returns false if all 3 main documents have not been signed" do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      student.update(demographics: true)
      expect(student.signed_main_documents?).to eq false
    end

    it "returns true if all 4 documents have been signed for a Seattle student and demographics form submitted" do
      FactoryBot.create(:completed_code_of_conduct, student: seattle_student)
      FactoryBot.create(:completed_refund_policy, student: seattle_student)
      FactoryBot.create(:completed_complaint_disclosure, student: seattle_student)
      FactoryBot.create(:completed_enrollment_agreement, student: seattle_student)
      seattle_student.update(demographics: true)
      expect(seattle_student.signed_main_documents?).to eq true
    end

    it "returns false if demographics form not submitted for a Seattle student" do
      FactoryBot.create(:completed_code_of_conduct, student: seattle_student)
      FactoryBot.create(:completed_refund_policy, student: seattle_student)
      FactoryBot.create(:completed_complaint_disclosure, student: seattle_student)
      FactoryBot.create(:completed_enrollment_agreement, student: seattle_student)
      expect(seattle_student.signed_main_documents?).to eq false
    end

    it "returns false if extra required Seattle document not signed" do
      FactoryBot.create(:completed_code_of_conduct, student: seattle_student)
      FactoryBot.create(:completed_refund_policy, student: seattle_student)
      FactoryBot.create(:completed_enrollment_agreement, student: seattle_student)
      seattle_student.update(demographics: true)
      expect(seattle_student.signed_main_documents?).to eq false
    end

    it "does not require refund policy for Fidgetech students" do
      student.courses = [FactoryBot.create(:course, description: 'Fidgetech')]
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.update(demographics: true)
      expect(student.signed_main_documents?).to eq true
    end
  end

  it "validates that the primary payment method belongs to the user", :stripe_mock do
    student = FactoryBot.create(:student)
    other_students_credit_card = FactoryBot.create(:credit_card)
    student.primary_payment_method = other_students_credit_card
    expect(student.valid?).to be false
  end

  describe "#stripe_customer", :stripe_mock do
    it "creates a Stripe Customer object for a student" do
      student = FactoryBot.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns the Stripe Customer object" do
      student = FactoryBot.create(:student)
      expect(student.stripe_customer).to be_an_instance_of(Stripe::Customer)
    end

    it "returns a Stripe Customer object if one already exists" do
      student = FactoryBot.create(:student)
      first_stripe_customer_return = student.stripe_customer
      second_stripe_customer_return = student.stripe_customer
      expect(first_stripe_customer_return.id).to eq second_stripe_customer_return.id
    end
  end

  describe "#stripe_customer_id", :stripe_mock do
    it "starts out nil" do
      student = FactoryBot.create(:student)
      expect(student.stripe_customer_id).to be_nil
    end

    it "is populated when a Stripe Customer object is created" do
      student = FactoryBot.create(:student)
      stripe_customer = student.stripe_customer
      expect(student.stripe_customer_id).to eq stripe_customer.id
    end
  end

  describe "#payment_methods" do
    it "returns all the student's bank accounts and credit cards", :vcr do
      student = FactoryBot.create(:student)
      credit_card_1 = FactoryBot.create(:credit_card, student: student)
      credit_card_2 = FactoryBot.create(:credit_card, student: student)
      bank_account = FactoryBot.create(:bank_account, student: student)
      expect(student.payment_methods).to match_array [credit_card_1, credit_card_2, bank_account]
    end
  end

  describe "#payment_methods_primary_first_then_pending" do
    it "returns payment methods with primary first, then pending bank accounts", :vcr do
      student = FactoryBot.create(:student)
      credit_card_1 = FactoryBot.create(:credit_card, student: student)
      bank_account = FactoryBot.create(:bank_account, student: student)
      credit_card_2 = FactoryBot.create(:credit_card, student: student)
      expect(student.payment_methods_primary_first_then_pending[0]).to eq credit_card_1
      expect(student.payment_methods_primary_first_then_pending[1]).to eq bank_account
    end
  end

  describe '#total_owed', :stripe_mock do
    let(:student) { FactoryBot.create :user_with_credit_card }

    before { allow(student).to receive(:total_paid).and_return(50_00) }

    it "calculates the total amount owed when no cost adjustments" do
      expect(student.total_owed).to eq student.plan.student_portion
    end

    it "calculates the total amount owed when positive cost adjustments" do
      student.cost_adjustments.create(amount: 50_00, reason: "test")
      expect(student.total_owed).to eq student.plan.student_portion + 50_00
    end

    it "calculates the total amount owed when positive and negative cost adjustments" do
      student.cost_adjustments.create(amount: 50_00, reason: "test")
      student.cost_adjustments.create(amount: -25_00, reason: "test")
      expect(student.total_owed).to eq student.plan.student_portion + 25_00
    end

    it "calculates the total amount owed on standard payment plan" do
      student.plan = FactoryBot.create(:standard_plan)
      expect(student.total_owed).to eq student.plan.student_portion
    end
  end

  describe '#total_remaining_owed', :stripe_mock do
    let(:student) { FactoryBot.create :user_with_verified_bank_account }

    before { allow(student).to receive(:total_paid).and_return(50_00) }

    it "calculated the total remaining amount owed" do
      expect(student.total_remaining_owed).to eq student.total_owed - student.total_paid
    end
  end

  describe '#upfront_amount_owed', :stripe_mock do
    it "calculates the upfront amount owed with upfront payment plan" do
      student = FactoryBot.create(:user_with_credit_card)
      allow(student).to receive(:total_paid).and_return(50_00)
      expect(student.upfront_amount_owed).to eq student.plan.student_portion - 50_00
      expect(student.upfront_amount_owed).to eq student.plan.upfront_amount - 50_00
    end

    it "calculates the upfront amount owed with standard payment plan" do
      student = FactoryBot.create(:user_with_credit_card, plan: FactoryBot.create(:standard_plan))
      allow(student).to receive(:total_paid).and_return(50_00)
      expect(student.upfront_amount_owed).to eq student.plan.upfront_amount - 50_00
      expect(student.upfront_amount_owed).to_not eq student.plan.student_portion - 50_00
    end

    it "calculates the upfront amount owed with standard payment plan with cost adjustment" do
      student = FactoryBot.create(:user_with_credit_card, plan: FactoryBot.create(:standard_plan))
      allow(student).to receive(:total_paid).and_return(50_00)
      student.cost_adjustments.create(amount: 25_00, reason: 'test')
      expect(student.upfront_amount_owed).to eq student.plan.upfront_amount - 25_00
      expect(student.upfront_amount_owed).to_not eq student.plan.student_portion - 25_00
    end
  end

  describe "#upfront_amount_with_fees", :stripe_mock do
    it "calculates the total upfront amount including fees" do
      plan = FactoryBot.create(:upfront_plan, upfront_amount: 200_00, student_portion: 200_00)
      student = FactoryBot.create(:student_with_credit_card, plan: plan)
      expect(student.upfront_amount_with_fees).to eq 206_00
    end

    it "calculates the total upfront amount on second payment including fees" do
      plan = FactoryBot.create(:upfront_plan, upfront_amount: 200_00, student_portion: 200_00)
      student = FactoryBot.create(:student_with_credit_card, plan: plan)
      FactoryBot.create(:payment_with_credit_card, student: student, amount: student.plan.upfront_amount - 100_00)
      expect(student.upfront_amount_with_fees).to eq 103_00
    end
  end

  describe "#upfront_payment_due?", :stripe_mock do
    let(:student) { FactoryBot.create :student_with_credit_card }

    it "is true if upfront_amount_owed is greater than 0" do
      expect(student.upfront_payment_due?).to eq true
    end

    it "is false if upfront_amount_owed is 0" do
      allow(student).to receive(:upfront_amount_owed).and_return(0)
      expect(student.upfront_payment_due?).to eq false
    end

    it "is true if student has paid only part of upfront payment", :stub_mailgun do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: student.plan.upfront_amount - 1)
      expect(student.upfront_payment_due?).to be true
    end

    it "is false if student has paid full upfront amount", :stub_mailgun do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: student.plan.upfront_amount)
      expect(student.upfront_payment_due?).to be false
    end

    it "is true if student has no payment plan selected" do
      student_without_plan = FactoryBot.create(:student, plan: nil)
      expect(student.upfront_payment_due?).to be true
    end
  end

  describe "#make_upfront_payment", :vcr, :stripe_mock, :stub_mailgun do
    let(:student) { FactoryBot.create :student_with_credit_card }

    it "makes a payment for the upfront amount of the student's plan if first payment" do
      student.make_upfront_payment
      expect(student.payments.first.amount).to eq student.plan.upfront_amount
    end

    it "makes a payment for the remaining upfront amount of the student's plan if second payment" do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: student.plan.upfront_amount - 100)
      student.make_upfront_payment
      expect(student.payments.order(:created_at).first.amount).to eq student.plan.upfront_amount - 100
      expect(student.payments.order(:created_at).last.amount).to eq 100
    end

    it "makes a payment using upfront_amount_owed when different from plan upfront_amount" do
      allow(student).to receive(:upfront_amount_owed).and_return(500_00)
      student.make_upfront_payment
      expect(student.payments.first.amount).to eq 500_00
    end

    it "sets category to upfront" do
      student.make_upfront_payment
      expect(student.payments.first.category).to eq 'upfront'
    end
  end

  describe '#signed_in_today?' do
    let(:student) { FactoryBot.create(:student) }

    it 'is false if the student has not signed in today' do
      expect(student.signed_in_today?).to eq false
    end

    it 'is true if the student has already signed in today' do
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(student.signed_in_today?).to eq true
      end
    end
  end

  describe '#signed_out_today?' do
    let(:student) { FactoryBot.create(:student) }

    it 'is false if the student has not signed out today' do
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(student.signed_out_today?).to eq false
      end
    end

    it 'is true if the student has signed out' do
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        attendance_record.update({:signing_out => true})
        expect(student.signed_out_today?).to eq true
      end
    end

    it 'populates the signed_out_time field for a students attendance record' do
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        attendance_record.update({:signing_out => true})
        expect(attendance_record.signed_out_time).to_not eq nil
      end
    end
  end

  describe '#class_in_session?' do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }

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
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }

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

  describe '#is_class_day?' do
    let(:course) { FactoryBot.create(:course) }
    let(:course_2) { FactoryBot.create(:future_course) }
    let(:student) { FactoryBot.create(:student, courses: [course, course_2]) }

    it 'returns true if during first course' do
      expect(student.is_class_day?(course.start_date)).to eq true
    end

    it 'returns true if during second course' do
      expect(student.is_class_day?(course_2.end_date)).to eq true
    end

    it 'returns falsy if not during either course' do
      expect(student.is_class_day?(course_2.end_date + 1.week)).to eq nil
    end

    it 'defaults to today if date not passed' do
      travel_to course.start_date do
        expect(student.is_class_day?).to eq true
      end
    end
  end

  describe '#is_classroom_day?' do
  let(:student) { FactoryBot.create(:student) }

  it 'returns true if today is monday class day for this course' do
    travel_to student.course.start_date.beginning_of_week do
      expect(student.is_classroom_day?).to eq true
    end
  end

  it 'returns false if today is class day but friday' do
    travel_to student.course.start_date.beginning_of_week + 4.days do
      expect(student.is_classroom_day?).to eq false
    end
  end
end

  describe '#completed_internship_course?' do
    let(:internship_course) { FactoryBot.create(:internship_course) }
    let(:student_with_internship_course) { FactoryBot.create(:student, course: internship_course) }
    let(:student_without_internship_course) { FactoryBot.create(:student) }

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

  describe '#passed_all_fulltime_code_reviews?', :stub_mailgun do
    let(:student) { FactoryBot.create(:student) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }
    let(:code_review_2) { FactoryBot.create(:code_review, course: student.course) }
    let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
    let(:submission_2) { FactoryBot.create(:submission, code_review: code_review_2, student: student) }

    it 'true if all code reviews are passing' do
      FactoryBot.create(:passing_review, submission: submission)
      FactoryBot.create(:passing_review, submission: submission_2)
      expect(student.passed_all_fulltime_code_reviews?).to eq(true)
    end

    it 'false if all code reviews are failing' do
      FactoryBot.create(:failing_review, submission: submission)
      FactoryBot.create(:failing_review, submission: submission_2)
      expect(student.passed_all_fulltime_code_reviews?).to eq(false)
    end

    it 'false if any code reviews are failing' do
      FactoryBot.create(:passing_review, submission: submission)
      FactoryBot.create(:failing_review, submission: submission_2)
      expect(student.passed_all_fulltime_code_reviews?).to eq(false)
    end

    it 'false if any code reviews are missing' do
      code_review_3 = FactoryBot.create(:code_review, course: student.course)
      FactoryBot.create(:passing_review, submission: submission)
      FactoryBot.create(:passing_review, submission: submission_2)
      expect(student.passed_all_fulltime_code_reviews?).to eq(false)
    end

    it 'true if fulltime code reviews passing but parttime code reviews failing' do
      pt_intro_course = FactoryBot.create(:part_time_course, track: FactoryBot.create(:part_time_track))
      student.courses << pt_intro_course
      pt_code_review = FactoryBot.create(:code_review, course: pt_intro_course)
      pt_submission = FactoryBot.create(:submission, code_review: pt_code_review, student: student)
      FactoryBot.create(:failing_review, submission: pt_submission)
      FactoryBot.create(:passing_review, submission: submission)
      FactoryBot.create(:passing_review, submission: submission_2)
      expect(student.passed_all_fulltime_code_reviews?).to eq(true)
    end
  end

  describe '#submission_for' do
    let(:student) { FactoryBot.create(:student) }
    let(:code_review_1) { FactoryBot.create(:code_review, course: student.course) }
    let(:code_review_2) { FactoryBot.create(:code_review, course: student.course) }
    let!(:submission_1) { FactoryBot.create(:submission, student: student, code_review: code_review_1) }

    it 'returns a student submission for a particular code review' do
      expect(student.submission_for(code_review_1)).to eq submission_1
    end
  end

  describe '#total_attendance_score' do
    let(:course_1) { FactoryBot.create(:past_course) }
    let(:course_2) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, courses: [course_1, course_2]) }

    it "calculates the student's attendance score when half absences" do
      course_1.class_days.each do |day|
        FactoryBot.create(:attendance_record, student: student, date: day, left_early: false, tardy: false)
      end
      travel_to course_2.end_date + 1.day do
        expect(student.total_attendance_score).to eq 50
      end
    end

    it "calculates the student's attendance score with left earlies and tardies" do
      course_1.class_days.each do |day|
        FactoryBot.create(:attendance_record, student: student, date: day, left_early: true, tardy: true)
      end
      travel_to course_2.end_date + 1.day do
        expect(student.total_attendance_score).to eq 0
      end
    end
  end

  describe '#attendance_score' do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let(:pair) { FactoryBot.create(:student, course: course) }

    it "calculates the student's attendance score" do
      day_one = student.course.start_date
      student.course.update(class_days: [day_one])

      travel_to day_one.beginning_of_day do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end

      travel_to day_one.end_of_day do
        expect(student.attendance_score(course)).to eq 50
      end
    end

    it "calculates the student attendance score with perfect attendance records" do
      day_one = student.course.start_date.in_time_zone(student.course.office.time_zone).to_date
      student.course.update(class_days: [day_one])
      travel_to day_one.in_time_zone(student.course.office.time_zone) + 8.hours do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to day_one.in_time_zone(student.course.office.time_zone) + 17.hours do
        student.attendance_records.last.update({signing_out: true})
        expect(student.attendance_score(course)).to eq 100
      end
    end

    it "calculates the student attendance score with no attendance records" do
      expect(student.attendance_score(course)).to eq 0
    end
  end

  describe '#absences' do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let(:pair) { FactoryBot.create(:student, course: course) }

    it "calculates the number of absences" do
      day_one = student.course.start_date
      student.course.update(class_days: [day_one])

      travel_to day_one.beginning_of_day do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
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
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end

      travel_to day_two.beginning_of_day do
        expect(student.absences(course)).to eq 1.5
      end
    end

    it "calculates the number of absences with perfect attendance records" do
      day_one = student.course.start_date.in_time_zone(student.course.office.time_zone).to_date
      student.course.update(class_days: [day_one])
      travel_to day_one.in_time_zone(student.course.office.time_zone) + 8.hours do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to day_one.in_time_zone(student.course.office.time_zone) + 17.hours do
        student.attendance_records.last.update({signing_out: true})
        expect(student.absences(course)).to eq 0
      end
    end
  end

  describe '#absences_cohort' do
    context 'ft cohort' do
      let(:ft_cohort) { FactoryBot.create(:intro_only_cohort) }
      let(:ft_student) { FactoryBot.create(:student, courses: ft_cohort.courses) }
      let(:pair) { FactoryBot.create(:student, courses: ft_cohort.courses) }
      before do
        ft_cohort.courses << FactoryBot.create(:course)
        ft_cohort.courses << FactoryBot.create(:internship_course)
        ft_cohort.courses.first.update(start_date: Date.today.beginning_of_week - 2.weeks, class_days: [Date.today.beginning_of_week - 2.weeks])
        ft_cohort.courses.second.update(start_date: Date.today.beginning_of_week - 1.week, class_days: [Date.today.beginning_of_week - 1.week])
      end

      it "with more than one course and perfect attendance" do
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.second.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 0
      end

      it "with more than one course and tardy" do
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: true, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.second.start_date, tardy: true, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 1
      end

      it "with more than one course and left early" do
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: false, left_early: true, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.second.start_date, tardy: false, left_early: true, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 1
      end

      it "with more than one course and 1 absence" do
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 1
      end

      it "with more than one course and 1 absence on a Sunday" do
        ft_cohort.courses.first.update_columns(start_date: Date.today.end_of_week - 2.weeks, class_days: [Date.today.end_of_week - 2.weeks])
        ft_cohort.courses.second.update_columns(start_date: Date.today.end_of_week - 1.week, class_days: [Date.today.end_of_week - 1.week])
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 2
      end

      it 'does not include course from another cohort' do
        extraneous_course = FactoryBot.create(:past_course)
        ft_student.courses << extraneous_course
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: ft_student, date: ft_cohort.courses.second.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(ft_student.absences_cohort).to eq 0
      end
    end

    context 'pt full stack cohort' do
      let(:pt_full_stack_cohort) { FactoryBot.create(:part_time_c_react_cohort) }
      let(:pt_full_stack_student) { FactoryBot.create(:student, courses: pt_full_stack_cohort.courses) }
      let(:pair) { FactoryBot.create(:student, courses: pt_full_stack_cohort.courses) }
      before do
        pt_full_stack_cohort.courses = [pt_full_stack_cohort.courses.first, pt_full_stack_cohort.courses.second]
        pt_full_stack_cohort.courses.first.update(start_date: Date.today.beginning_of_week - 2.weeks, class_days: [Date.today.beginning_of_week - 2.weeks])
        pt_full_stack_cohort.courses.second.update(start_date: Date.today.beginning_of_week - 1.week, class_days: [Date.today.beginning_of_week - 1.week])
      end

      it "with more than one course and perfect attendance" do
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.second.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_full_stack_student.absences_cohort).to eq 0
      end

      it "with more than one course and tardy" do
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.first.start_date, tardy: true, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.second.start_date, tardy: true, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_full_stack_student.absences_cohort).to eq 1
      end

      it "with more than one course and left early" do
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.first.start_date, tardy: false, left_early: true, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.second.start_date, tardy: false, left_early: true, pairings_attributes: [pair_id: pair.id])
        expect(pt_full_stack_student.absences_cohort).to eq 1
      end

      it "with more than one course and 1 absence" do
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_full_stack_student.absences_cohort).to eq 1
      end

      it 'does not include course from another cohort' do
        extraneous_course = FactoryBot.create(:past_course)
        pt_full_stack_student.courses << extraneous_course
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:attendance_record, student: pt_full_stack_student, date: pt_full_stack_cohort.courses.second.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_full_stack_student.absences_cohort).to eq 0
      end
    end

    context 'pt intro cohort' do
      let(:pt_intro_cohort) { FactoryBot.create(:part_time_cohort) }
      let(:pt_intro_student) { FactoryBot.create(:student, courses: pt_intro_cohort.courses) }
      let(:pair) { FactoryBot.create(:student, courses: pt_intro_cohort.courses) }
      before do
        pt_intro_cohort.courses.first.update(start_date: Date.today.beginning_of_week - 1.week, class_days: [Date.today.beginning_of_week - 1.week])
      end

      it "with perfect attendance" do
        FactoryBot.create(:attendance_record, student: pt_intro_student, date: pt_intro_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_intro_student.absences_cohort).to eq 0
      end

      it "with tardy" do
        FactoryBot.create(:attendance_record, student: pt_intro_student, date: pt_intro_cohort.courses.first.start_date, tardy: true, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_intro_student.absences_cohort).to eq 0.5
      end

      it "with left early" do
        FactoryBot.create(:attendance_record, student: pt_intro_student, date: pt_intro_cohort.courses.first.start_date, tardy: false, left_early: true, pairings_attributes: [pair_id: pair.id])
        expect(pt_intro_student.absences_cohort).to eq 0.5
      end

      it "with 1 absence" do
        expect(pt_intro_student.absences_cohort).to eq 1
      end

      it 'does not include course from another cohort' do
        extraneous_course = FactoryBot.create(:past_course)
        pt_intro_student.courses << extraneous_course
        FactoryBot.create(:attendance_record, student: pt_intro_student, date: pt_intro_cohort.courses.first.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
        expect(pt_intro_student.absences_cohort).to eq 0
      end
    end
  end

  describe '#solos' do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }

    it "calculates the number of solos when none" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student)
      end
      travel_to course.start_date + 2.days do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 2
    end

    it "calculates the number of solos when some" do
      travel_to course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: FactoryBot.create(:student).id])
      end
      travel_to course.start_date + 2.days do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end

    it "ignores friday solos" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student)
      end
      travel_to course.start_date + 4.days do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end

    it "only counts within this course" do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student)
      end
      future_course = FactoryBot.create(:future_course)
      student.courses << future_course
      travel_to future_course.start_date do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.solos(course)).to eq 1
    end
  end

  describe '#attendance_records_for' do
    let(:course) { FactoryBot.create(:course) }
    let(:past_course) { FactoryBot.create(:past_course) }
    let(:future_course) { FactoryBot.create(:future_course) }
    let(:internship_course) { FactoryBot.create(:internship_course) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let(:pair) { FactoryBot.create(:student, course: course) }

    it 'counts the number of days the student has been on time to class' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours do
        attendance_record = FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 17.hours do
        student.attendance_records.last.update({:signing_out => true})
      end
      expect(student.attendance_records_for(:on_time)).to eq 1
    end

    it 'counts the number of days the student has been tardy' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 9.hours + 20.minutes do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 9.hours + 1.day do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      expect(student.attendance_records_for(:tardy)).to eq 2
    end

    it 'counts the number of days the student has left early (failed to sign out)' do
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours + 55.minutes do
        attendance_record = FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to course.start_date.in_time_zone(course.office.time_zone) + 15.hours do
        student.attendance_records.last.update({:signing_out => true})
      end
      expect(student.attendance_records_for(:left_early)).to eq 1
    end

    it 'returns 0 if absences is negative' do
      travel_to course.start_date do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to course.start_date + 2.days do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      travel_to course.end_date do
        expect(student.attendance_records_for(:absent)).to eq 23
      end
    end

    it 'counts the number of days the student has been absent' do
      course.class_days = [Date.parse('2020-01-06')]
      course.save
      travel_to course.class_days.first do
        FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: pair.id])
      end
      expect(student.attendance_records_for(:absent)).to eq 0
    end

    it 'counts absences double on Sundays' do
      course.class_days = [Date.parse('2020-01-05')]
      course.save
      expect(student.attendance_records_for(:absent)).to eq 2
    end

    it 'includes 2021 solos in number of days the student has been absent' do
      course.class_days = [Date.parse('2021-01-04')]
      course.save
      travel_to course.class_days.first do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.attendance_records_for(:absent)).to eq 1
    end

    it 'counts even solo records when passed :all status' do
      course.class_days = [Date.parse('2021-01-04')]
      course.save
      travel_to course.class_days.first do
        FactoryBot.create(:attendance_record, student: student)
      end
      expect(student.attendance_records_for(:all)).to eq 1
    end

    context 'for a particular course' do
      it 'counts the number of days the student has been on time to class' do
        student.courses << future_course
        FactoryBot.create(:on_time_attendance_record, student: student, date: course.start_date, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:on_time_attendance_record, student: student, date: future_course.end_date, pairings_attributes: [pair_id: pair.id])
        expect(student.attendance_records_for(:on_time, course)).to eq 1
      end

      it 'counts the number of days the student has been tardy' do
        student.courses << future_course
        FactoryBot.create(:tardy_attendance_record, student: student, date: course.start_date, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:tardy_attendance_record, student: student, date: future_course.end_date, pairings_attributes: [pair_id: pair.id])
        expect(student.attendance_records_for(:tardy, course)).to eq 1
      end

      it 'counts the number of days the student has left early (failed to sign out)' do
        student.courses << future_course
        FactoryBot.create(:left_early_attendance_record, student: student, date: course.start_date, pairings_attributes: [pair_id: pair.id])
        FactoryBot.create(:left_early_attendance_record, student: student, date: future_course.end_date, pairings_attributes: [pair_id: pair.id])
        expect(student.attendance_records_for(:left_early, course)).to eq 1
      end

      it 'counts the number of days the student has been absent' do
        student.courses << past_course
        student.courses << future_course
        FactoryBot.create(:attendance_record, student: student, date: future_course.start_date, pairings_attributes: [pair_id: pair.id])
        expect(student.attendance_records_for(:absent, past_course)).to eq past_course.class_days.count
      end

      it 'counts absences double on Sundays' do
        course.class_days = [Date.parse('2020-01-05')]
        course.save
        expect(student.attendance_records_for(:absent, course)).to eq 2
      end
    end

    context 'for a particular range of courses' do
      before do
        student.courses = [past_course, course, future_course]
        student.courses.reload.each do |c|
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
        travel_to future_course.end_date do
          expect(student.attendance_records_for(:absent, past_course, future_course)).to eq attended
        end
      end

      it 'counts absences double on Sundays' do
        past_course.update_columns(start_date: Date.parse('2020-01-05'), class_days: [Date.parse('2020-01-05')] + past_course.class_days)
        attended = past_course.total_class_days + course.total_class_days + future_course.total_class_days - AttendanceRecord.count
        travel_to future_course.end_date do
          expect(student.attendance_records_for(:absent, past_course, future_course)).to eq attended + 1
        end
      end
    end
  end

  describe '#total_paid', :vcr, :stripe_mock, :stub_mailgun do
    it 'sums all of the students payments' do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      expect(student.total_paid).to eq 400_00
    end

    it 'does not include failed payments' do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      failed_payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      failed_payment.update(status: 'failed')
      expect(student.total_paid).to eq 200_00
    end

    it 'subtracts refunds' do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00, offline: true)
      payment.update(refund_amount: 5000)
      expect(student.total_paid).to eq 150_00
    end

    it 'includes negative offline transactions' do
      student = FactoryBot.create(:student_with_credit_card, email: 'example@example.com')
      payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 0, refund_amount: 200_00, offline: true)
      expect(student.total_paid).to eq -200_00
    end
  end

  describe '#total_paid_online', :vcr, :stripe_mock, :stub_mailgun do
    let(:student) { FactoryBot.create(:student_with_credit_card, email: 'example@example.com') }

    it 'sums all of the stripe payments only' do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      FactoryBot.create(:payment, student: student, amount: 100_00, offline: true)
      expect(student.total_paid_online).to eq 200_00
    end

    it 'includes online refunds only' do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00, refund_amount: 50_00)
      FactoryBot.create(:payment, student: student, amount: 100_00, offline: true, refund_amount: 25_00)
      expect(student.total_paid_online).to eq 150_00
    end
  end

  describe '#total_paid_offline', :vcr, :stripe_mock, :stub_mailgun do
    let(:student) { FactoryBot.create(:student_with_credit_card, email: 'example@example.com') }

    it 'sums all of the offline payments only' do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00)
      FactoryBot.create(:payment, student: student, amount: 100_00, offline: true)
      expect(student.total_paid_offline).to eq 100_00
    end

    it 'includes offline refunds only' do
      FactoryBot.create(:payment_with_credit_card, student: student, amount: 200_00, refund_amount: 50_00)
      FactoryBot.create(:payment, student: student, amount: 100_00, offline: true, refund_amount: 25_00)
      expect(student.total_paid_offline).to eq 75_00
    end
  end

  describe '#find_rating' do
    it 'finds the rating based on internship' do
      student = FactoryBot.create(:student)
      internship = FactoryBot.create(:internship)
      rating = FactoryBot.create(:rating, student: student, internship: internship)
      expect(student.find_rating(internship)).to eq(rating)
    end
  end

  describe "abilities" do
    let(:student) { FactoryBot.create(:student) }
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
      let(:bank_account) { FactoryBot.create(:bank_account, student: student) }
      let(:credit_card) { FactoryBot.create(:credit_card, student: student) }

      it 'allows students to create payments using one of their payment methods', :vcr do
        is_expected.to have_abilities(:create, Payment.new(payment_method: bank_account, student_id: student.id))
        is_expected.to have_abilities(:create, Payment.new(payment_method: credit_card, student_id: student.id))
      end

      it "doesn't allow students to create payments for others' payment methods", :vcr do
        another_bank_account = FactoryBot.create(:bank_account)
        another_credit_card = FactoryBot.create(:credit_card)
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_bank_account))
        is_expected.to not_have_abilities(:create, Payment.new(payment_method: another_credit_card))
      end

      it "doesn't allow students to create payments for other students", :stripe_mock do
        another_student = FactoryBot.create(:student)
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
        student.enrollments.destroy_all
        student.course = FactoryBot.create(:internship_course)
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

    context 'for cost adjustments' do
      it { is_expected.to not_have_abilities([:create, :read, :update, :destroy], CostAdjustment.new)}
    end
  end

  describe 'paranoia' do
    let(:student) { FactoryBot.create(:student) }
    let!(:ar) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }

    it 'archives destroyed user' do
      student.destroy
      expect(Student.count).to eq 0
      expect(Student.with_deleted.count).to eq 1
    end

    it 'restores archived user' do
      student.destroy
      student.restore
      expect(Student.count).to eq 1
    end

    it 'clears CRM student id & invitation token when student expunged' do
      allow_any_instance_of(CrmLead).to receive(:update).and_return({})
      expect_any_instance_of(CrmLead).to receive(:update).with({Rails.application.config.x.crm_fields['EPICENTER_ID'] => nil, Rails.application.config.x.crm_fields['INVITATION_TOKEN'] => nil })
      student.really_destroy
    end
  end

  describe 'enrolled?' do
    it 'reports enrolled with full-time cohort' do
      cohort = FactoryBot.create(:cohort_with_internship)
      student = FactoryBot.create(:student, courses: cohort.courses)
      expect(student.enrolled?).to eq true
    end

    it 'reports enrolled with part-time cohort' do
      cohort = FactoryBot.create(:part_time_cohort, courses: [FactoryBot.create(:part_time_course)])
      student = FactoryBot.create(:student, courses: cohort.courses)
      expect(student.enrolled?).to eq true
    end

    it 'reports not enrolled with no cohort' do
      student = FactoryBot.create(:student_without_courses)
      expect(student.enrolled?).to eq false
    end
  end

  describe 'get_status' do
    let(:student) { FactoryBot.create(:student) }

    it 'reports status when student is archived' do
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
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
      student.courses = [FactoryBot.create(:future_course)]
      expect(student.get_status).to eq 'Future student'
    end

    it 'reports status of graduated student' do
      student.courses = [FactoryBot.create(:internship_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Graduate'
    end

    it 'reports status of student who finished before 2016' do
      student.courses = [FactoryBot.create(:internship_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Graduate'
    end

    it 'reports status of student who withdrew (class over without completed internship course)' do
      student.courses = [FactoryBot.create(:course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Incomplete'
    end

    it 'reports status of student who withdrew (withdrawn enrollments only)' do
      student.courses = [FactoryBot.create(:course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      Enrollment.find_by(student: student).destroy
      expect(student.get_status).to eq 'Incomplete'
    end

    it 'reports status of past part-time student' do
      student.courses = [FactoryBot.create(:part_time_course, class_days: [(Time.zone.now.to_date - 5.weeks).monday])]
      expect(student.get_status).to eq 'Part-time (past)'
    end

    it 'reports status of current part-time student' do
      student.courses = [FactoryBot.create(:part_time_course)]
      expect(student.get_status).to eq 'Part-time (current)'
    end

    it 'reports status of future part-time student' do
      student.courses = [FactoryBot.create(:part_time_course, class_days: [(Time.zone.now.to_date + 5.weeks).monday])]
      expect(student.get_status).to eq 'Part-time (future)'
    end
  end

  describe '#archive_enrollments' do
    it 'archives all enrollments when student destroyed' do
      student = FactoryBot.create(:student)
      enrollment_id = student.enrollments.first.id
      student.destroy
      expect(Enrollment.find_by_id(enrollment_id)).to eq nil
    end
  end

  describe 'calculate cohorts' do
    let!(:cohort) { FactoryBot.create(:full_cohort, start_date: Date.today.beginning_of_week) }
    let!(:past_cohort) { FactoryBot.create(:full_cohort, start_date: Date.today.beginning_of_week - 1.year) }
    let!(:future_cohort) { FactoryBot.create(:full_cohort, start_date: Date.today.beginning_of_week + 1.year) }
    let!(:part_time_cohort) { FactoryBot.create(:part_time_cohort, start_date: Date.today.beginning_of_week) }
    let!(:part_time_full_stack_cohort) { FactoryBot.create(:part_time_c_react_cohort, start_date: Date.today.beginning_of_week) }
    let!(:part_time_js_react_cohort) { FactoryBot.create(:part_time_js_react_cohort, start_date: Date.today.beginning_of_week) }

    describe '#calculate_parttime_cohort' do
      it 'returns part-time cohort when only part-time intro courses' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first])
        expect(student.calculate_parttime_cohort).to eq part_time_cohort
      end

      it 'returns part-time cohort when only part-time js/react courses' do
        student = FactoryBot.create(:student, courses: [part_time_js_react_cohort.courses.first])
        expect(student.calculate_parttime_cohort).to eq part_time_js_react_cohort
      end

      it 'returns nil when when no part-time intro or js/reacat course' do
        student = FactoryBot.create(:student, courses: [cohort.courses.first, part_time_full_stack_cohort.courses.first])
        expect(student.calculate_parttime_cohort).to eq nil
      end

      it 'returns Fidgetech cohort when only Fidgetech cohort' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first])
        student.course.update(description: 'Fidgetech', parttime: false)
        expect(student.calculate_parttime_cohort).to eq part_time_cohort
      end
    end

    describe '#calculate_starting_cohort' do
      it 'returns nil when only part-time courses' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first, part_time_js_react_cohort.courses.first])
        expect(student.calculate_starting_cohort).to eq nil
      end

      it 'returns full-time cohort when part-time and full-time courses' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first] + future_cohort.courses)
        expect(student.calculate_starting_cohort).to eq future_cohort
      end

      it 'returns first full-time cohort under normal conditions' do
        student = FactoryBot.create(:student, courses: future_cohort.courses + cohort.courses)
        expect(student.calculate_starting_cohort).to eq cohort
      end

      it 'returns part-time full-stack cohort' do
        student = FactoryBot.create(:student, courses: part_time_full_stack_cohort.courses)
        expect(student.calculate_starting_cohort).to eq part_time_full_stack_cohort
      end
    end

    describe '#calculate_current_cohort' do
      it 'returns nil when no internship course and no part-time full-stack cohort' do
        student = FactoryBot.create(:student, courses: [cohort.courses.first])
        expect(student.calculate_current_cohort).to eq nil
      end

      it 'returns last full-time cohort under normal conditions' do
        student = FactoryBot.create(:student, courses: future_cohort.courses + cohort.courses)
        expect(student.calculate_current_cohort).to eq future_cohort
      end

      it 'returns correct cohort when internship course belongs to multiple cohorts' do
        cohort.courses.last.cohorts << future_cohort
        student = FactoryBot.create(:student, courses: future_cohort.courses)
        expect(student.calculate_current_cohort).to eq future_cohort
      end

      it 'returns part-time full-stack cohort when internship & non-internship course from that cohort is present' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first, cohort.courses.first, part_time_full_stack_cohort.courses.first, part_time_full_stack_cohort.courses.last])
        expect(student.calculate_current_cohort).to eq part_time_full_stack_cohort
      end

      it 'returns nil when only Fidgetech cohort' do
        student = FactoryBot.create(:student, courses: [part_time_cohort.courses.first])
        student.course.update(description: 'Fidgetech', parttime: false)
        expect(student.calculate_current_cohort).to eq nil
      end
    end

    describe '#possible_cirr_cohorts' do
      it 'returns possible ft or pt-full-stack cohorts based on courses' do
        student = FactoryBot.create(:student, courses: future_cohort.courses + cohort.courses)
        expect(student.possible_cirr_cohorts).to eq [cohort, future_cohort]
      end
    end
  end

  describe '.invite', :dont_stub_crm do
    let(:cohort) { FactoryBot.create(:full_cohort) }

    before { allow_any_instance_of(CrmLead).to receive(:cohort).and_return(cohort) }

    it 'manually invites student to Epicenter without sending email' do
      emails_sent = Devise.mailer.deliveries.count
      Student.invite(email: 'example@example.com')
      student = Student.find_by(email: 'example@example.com')
      expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
      expect(student.courses.count).to eq 5
      expect(student.courses.last.description).to_not eq 'Internship Exempt'
      expect(student.cohort.description).to eq cohort.description
      expect(student.office).to eq cohort.office
      expect(Devise.mailer.deliveries.count).to eq(emails_sent)
    end
  end

  describe '#fulltime?, #parttime?, #fidgetech?' do
    it 'returns true if student ending_cohort is a fulltime cohort' do
      student = FactoryBot.create(:student_with_cohort)
      expect(student.fulltime?).to eq true
      expect(student.parttime?).to eq false
      expect(student.fidgetech?).to eq false
    end

    it 'returns true if student ending_cohort is a parttime cohort' do
      student = FactoryBot.create(:part_time_student_with_cohort)
      expect(student.fulltime?).to eq false
      expect(student.parttime?).to eq true
      expect(student.fidgetech?).to eq false
    end

    it 'returns true if student ending_cohort is Fidgetech' do
      student = FactoryBot.create(:fidgetech_student_with_cohort)
      expect(student.fulltime?).to eq false
      expect(student.parttime?).to eq false
      expect(student.fidgetech?).to eq true
    end
  end
end

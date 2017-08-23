describe Enrollment do

  it { should validate_presence_of :course }
  it { should validate_presence_of :student }

  describe 'validations' do
    it 'validates uniqueness of student_id to course_id' do
      student = FactoryGirl.create(:student)
      course = FactoryGirl.create(:course)
      Enrollment.create(student: student, course: course)
      should validate_uniqueness_of(:student_id).scoped_to(:course_id)
    end
  end

  describe 'archiving enrollments when withdrawing students' do
    let(:past_course) { FactoryGirl.create(:past_course) }
    let(:future_course) { FactoryGirl.create(:future_course) }

    context 'before course start date' do
      let(:student) { FactoryGirl.create(:student, course: future_course) }

      it 'permanently destroys enrollment' do
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end
    end

    context 'after course start date' do
      let(:student) { FactoryGirl.create(:student, course: past_course) }

      it 'permanently destroys enrollment if no attendance record exists' do
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end

      it 'archives internship course enrollment regardless of attendance' do
        student.courses = [FactoryGirl.create(:internship_course)]
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end

      it 'archives enrollment with paranoia if attendance record exists' do
        FactoryGirl.create(:attendance_record, student: student, date: student.course.start_date)
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end
    end
  end

  describe 'setting starting_cohort_id' do
    let(:student) { FactoryGirl.create(:student, courses: []) }
    let(:course) { FactoryGirl.create(:course) }
    let(:past_course) { FactoryGirl.create(:past_course) }
    let(:future_course) { FactoryGirl.create(:future_course) }
    let(:part_time_course) { FactoryGirl.create(:part_time_course) }

    context 'adding new enrollments' do
      it 'updates cohort when adding first course' do
        student.course = course
        expect(student.starting_cohort_id).to eq course.id
      end

      it 'updates cohort when adding second course with earlier start date' do
        student.course = course
        student.course = past_course
        expect(student.starting_cohort_id).to eq past_course.id
      end

      it 'does not update cohort when adding second course with later start date' do
        student.course = course
        student.course = future_course
        expect(student.starting_cohort_id).to eq course.id
      end

      it 'does not update cohort when adding part-time course' do
        student.course = part_time_course
        expect(student.starting_cohort_id).to eq nil
      end
    end

    context 'removing enrollments' do

      before do
        student.course = course
        FactoryGirl.create(:attendance_record, student: student, date: course.start_date)
      end

      it 'does not update cohort when archiving enrollment' do
        student.enrollments.first.destroy
        expect(student.starting_cohort_id).to eq course.id
      end

      it 'clears cohort when permanently removing the only enrollment' do
        student.enrollments.first.really_destroy!
        expect(student.starting_cohort_id).to eq nil
      end

      it 'updates cohort when removing course with earlier start date' do
        student.course = past_course
        student.enrollments.find_by(course: past_course).really_destroy!
        expect(student.starting_cohort_id).to eq course.id
      end
    end
  end

  describe 'internship class in CRM' do
    let(:student) { FactoryGirl.create(:student, courses: []) }
    let(:course) { FactoryGirl.create(:course) }
    let(:internship_course) { FactoryGirl.create(:internship_course) }

    it 'is set when enrolled in internship course' do
      location = internship_course.office.name
      location = 'PDX' if location == 'Portland'
      location = 'SEA' if location == 'Seattle'
      description = "#{location} #{internship_course.description.split.first} #{internship_course.start_date.strftime('%b %-d')} - #{internship_course.end_date.strftime('%b %-d')}"
      expect(student).to receive(:update_close_io).with({ 'custom.lcf_Uhma73rkvzxw7h24fhtnXPfxNYLUPkWckEflCTRykgp': description })
      student.course = internship_course
    end

    it 'is removed when removed from internship course' do
      student.course = internship_course
      expect(student).to receive(:update_close_io).with({ 'custom.lcf_Uhma73rkvzxw7h24fhtnXPfxNYLUPkWckEflCTRykgp': nil })
      student.enrollments.first.destroy
    end

    it 'is not changed when enrolled in non-internship course' do
      location = course.office.name
      location = 'PDX' if location == 'Portland'
      location = 'SEA' if location == 'Seattle'
      description = "#{location} #{course.description.split.first} #{course.start_date.strftime('%b %-d')} - #{course.end_date.strftime('%b %-d')}"
      expect(student).to_not receive(:update_close_io).with({ 'custom.lcf_Uhma73rkvzxw7h24fhtnXPfxNYLUPkWckEflCTRykgp': description })
      student.course = course
    end

    it 'is not changed when removed from non-internship course' do
      student.course = course
      expect(student).to_not receive(:update_close_io).with({ 'custom.lcf_Uhma73rkvzxw7h24fhtnXPfxNYLUPkWckEflCTRykgp': nil })
      student.enrollments.first.destroy
    end
  end
end

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

  describe 'sets starting and ending cohort' do
    let(:student) { FactoryGirl.create(:student, courses: []) }
    let(:past_cohort) { FactoryGirl.create(:cohort, start_date: (Date.today - 1.year).beginning_of_week) }
    let(:current_cohort) { FactoryGirl.create(:cohort, start_date: Date.today.beginning_of_week) }
    let(:future_cohort) { FactoryGirl.create(:cohort, start_date: (Date.today + 1.year).beginning_of_week) }
    let(:part_time_course) { FactoryGirl.create(:part_time_course) }

    context 'adding new enrollments' do
      it 'updates starting & ending cohort when adding first course' do
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Starting Cohort': current_cohort.description, 'custom.Ending Cohort': current_cohort.description })
        student.course = current_cohort.courses.first
        expect(student.starting_cohort).to eq current_cohort
        expect(student.ending_cohort).to eq current_cohort
      end

      it 'updates only starting cohort when adding second course from earlier cohort' do
        student.course = current_cohort.courses.first
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Starting Cohort': past_cohort.description })
        student.course = past_cohort.courses.first
        expect(student.starting_cohort_id).to eq past_cohort.id
      end

      it 'updates only ending cohort when adding second course with later start date' do
        student.course = current_cohort.courses.first
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Ending Cohort': current_cohort.description })
        student.course = future_cohort.courses.first
        expect(student.starting_cohort_id).to eq current_cohort.id
      end

      it 'does not update starting or ending cohort when adding part-time course' do
        expect_any_instance_of(CrmLead).to_not receive(:update)
        student.course = part_time_course
        expect(student.starting_cohort_id).to eq nil
      end

      it 'updates ending cohort correctly when enrolling in internship course belonging to multiple cohorts' do
        full_cohort = FactoryGirl.create(:full_cohort)
        future_cohort.courses << full_cohort.courses.internship_courses.last
        full_cohort.courses.each { |course| student.courses << course }
        expect(student.ending_cohort).to eq full_cohort
      end
    end

    context 'removing enrollments' do
      before do
        course = current_cohort.courses.first
        student.course = course
        FactoryGirl.create(:attendance_record, student: student, date: course.start_date)
      end

      it 'does not update starting or ending cohort when just archiving enrollment' do
        expect_any_instance_of(CrmLead).to_not receive(:update)
        student.enrollments.first.destroy
        expect(student.starting_cohort_id).to eq current_cohort.id
      end

      it 'clears starting & ending cohort when permanently removing the only enrollment' do
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Starting Cohort': nil, 'custom.Ending Cohort': nil })
        student.enrollments.first.really_destroy!
        expect(student.starting_cohort_id).to eq nil
        expect(student.ending_cohort_id).to eq nil
      end

      it 'updates only starting cohort when removing course from earlier cohort' do
        past_course = past_cohort.courses.first
        student.course = past_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Starting Cohort': current_cohort.description })
        student.enrollments.find_by(course: past_course).really_destroy!
        expect(student.starting_cohort_id).to eq current_cohort.id
      end

      it 'updates only ending cohort when removing course from later cohort' do
        future_course = future_cohort.courses.first
        student.course = future_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Ending Cohort': current_cohort.description })
        student.enrollments.find_by(course: future_course).really_destroy!
        expect(student.ending_cohort_id).to eq current_cohort.id
      end
    end
  end

  describe 'internship class in CRM' do
    let(:student) { FactoryGirl.create(:student, courses: []) }
    let(:course) { FactoryGirl.create(:course) }
    let(:internship_course) { FactoryGirl.create(:internship_course) }

    it 'is set when enrolled in internship course' do
      expect_any_instance_of(CrmLead).to receive(:update_internship_class).with(internship_course)
      student.course = internship_course
    end

    it 'is removed when removed from internship course' do
      student.course = internship_course
      expect_any_instance_of(CrmLead).to receive(:update_internship_class).with(nil)
      student.enrollments.first.destroy
    end

    it 'is set to other internship course when second internship course removed' do
      new_internship_course = FactoryGirl.create(:internship_course, class_days: [internship_course.start_date + 5.weeks])
      student.courses = [internship_course, new_internship_course]
      expect_any_instance_of(CrmLead).to receive(:update_internship_class).with(internship_course)
      new_internship_course.enrollments.first.destroy
    end

    it 'is not changed when enrolled in non-internship course' do
      expect_any_instance_of(CrmLead).to_not receive(:update_internship_class)
      student.course = course
    end

    it 'is not changed when removed from non-internship course' do
      student.course = course
      expect_any_instance_of(CrmLead).to_not receive(:update_internship_class)
      student.enrollments.first.destroy
    end
  end
end

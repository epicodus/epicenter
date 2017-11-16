describe Enrollment do

  it { should validate_presence_of :course }
  it { should validate_presence_of :student }

  describe 'validations' do
    it 'validates uniqueness of student_id to course_id' do
      student = FactoryBot.create(:student)
      course = FactoryBot.create(:course)
      Enrollment.create(student: student, course: course)
      should validate_uniqueness_of(:student_id).scoped_to(:course_id)
    end
  end

  describe 'archiving enrollments when withdrawing students' do
    let(:past_course) { FactoryBot.create(:past_course) }
    let(:future_course) { FactoryBot.create(:future_course) }

    context 'before course start date' do
      let(:student) { FactoryBot.create(:student, course: future_course) }

      it 'permanently destroys enrollment' do
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end
    end

    context 'after course start date' do
      let(:student) { FactoryBot.create(:student, course: past_course) }

      it 'permanently destroys enrollment if no attendance record exists' do
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end

      it 'archives internship course enrollment regardless of attendance' do
        student.courses = [FactoryBot.create(:internship_course)]
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end

      it 'archives enrollment with paranoia if attendance record exists' do
        FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end
    end
  end

  describe 'sets starting and ending cohort' do
    let(:student) { FactoryBot.create(:student, courses: []) }
    let(:past_cohort) { FactoryBot.create(:cohort_internship_course, start_date: (Date.today - 1.year).beginning_of_week) }
    let(:current_cohort) { FactoryBot.create(:cohort_internship_course, start_date: Date.today.beginning_of_week) }
    let(:future_cohort) { FactoryBot.create(:cohort_internship_course, start_date: (Date.today + 1.year).beginning_of_week) }
    let(:part_time_course) { FactoryBot.create(:part_time_course) }
    let(:non_internship_course) { FactoryBot.create(:course) }

    context 'adding new enrollments' do
      it 'updates starting & ending cohort when adding first course' do
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': current_cohort.description, 'custom.Cohort - Current': current_cohort.description })
        student.course = current_cohort.courses.last
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq current_cohort
      end

      it 'updates only starting cohort when adding second course from earlier cohort' do
        student.course = current_cohort.courses.first
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': past_cohort.description })
        student.course = past_cohort.courses.first
        expect(student.starting_cohort_id).to eq past_cohort.id
      end

      it 'updates only ending cohort when adding second course with later start date' do
        student.course = current_cohort.courses.first
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': current_cohort.description })
        student.course = future_cohort.courses.first
        expect(student.starting_cohort_id).to eq current_cohort.id
      end

      it 'does not update starting or ending cohort when adding part-time course' do
        expect_any_instance_of(CrmLead).to_not receive(:update)
        student.course = part_time_course
        expect(student.starting_cohort_id).to eq nil
      end

      it 'does not update starting or ending cohort when adding non-internship course' do
        expect_any_instance_of(CrmLead).to_not receive(:update)
        student.course = non_internship_course
        expect(student.starting_cohort_id).to eq nil
      end

      it 'updates ending cohort correctly when enrolling in internship course belonging to multiple cohorts' do
        full_cohort = FactoryBot.create(:full_cohort)
        future_cohort.courses << full_cohort.courses.internship_courses.last
        full_cohort.courses.each { |course| student.courses << course }
        expect(student.cohort).to eq full_cohort
      end
    end

    context 'removing enrollments' do
      before do
        course = current_cohort.courses.first
        student.course = course
        FactoryBot.create(:attendance_record, student: student, date: course.start_date)
      end

      it 'updates ending cohort only when just archiving enrollment' do
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': nil })
        student.enrollments.first.destroy
        expect(student.starting_cohort_id).to eq current_cohort.id
        expect(student.cohort_id).to eq nil
      end

      it 'clears starting & ending cohort when permanently removing the only enrollment' do
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': nil, 'custom.Cohort - Current': nil })
        student.enrollments.first.really_destroy!
        expect(student.starting_cohort_id).to eq nil
        expect(student.cohort_id).to eq nil
      end

      it 'updates only starting cohort when removing course from earlier cohort' do
        past_course = past_cohort.courses.first
        student.course = past_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': current_cohort.description })
        student.enrollments.find_by(course: past_course).really_destroy!
        expect(student.starting_cohort_id).to eq current_cohort.id
      end

      it 'updates only ending cohort when removing course from later cohort' do
        future_course = future_cohort.courses.first
        student.course = future_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': current_cohort.description })
        student.enrollments.find_by(course: future_course).really_destroy!
        expect(student.cohort_id).to eq current_cohort.id
      end

      it 'clears only ending cohort when removing last internship course' do
        full_cohort_student = FactoryBot.create(:student_in_full_cohort)
        full_cohort = full_cohort_student.cohort
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': nil })
        full_cohort_student.enrollments.find_by(course: full_cohort.courses.last).really_destroy!
        expect(full_cohort_student.starting_cohort).to eq full_cohort
        expect(full_cohort_student.cohort).to eq nil
      end
    end
  end

  describe 'internship class in CRM' do
    let(:student) { FactoryBot.create(:student, courses: []) }
    let(:course) { FactoryBot.create(:course) }
    let(:internship_course) { FactoryBot.create(:internship_course) }

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
      new_internship_course = FactoryBot.create(:internship_course, class_days: [internship_course.start_date + 5.weeks])
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

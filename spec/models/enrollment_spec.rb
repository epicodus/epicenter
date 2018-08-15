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

  describe 'updates cohorts only when changes' do
    let(:student) { FactoryBot.create(:student, courses: []) }
    let(:past_cohort) { FactoryBot.create(:full_cohort, start_date: (Date.today - 1.year).beginning_of_week) }
    let(:current_cohort) { FactoryBot.create(:full_cohort, start_date: Date.today.beginning_of_week - 1.week) }
    let(:future_cohort) { FactoryBot.create(:full_cohort, start_date: (Date.today + 1.year).beginning_of_week) }
    let(:part_time_cohort) { FactoryBot.create(:part_time_cohort, start_date: Date.today.beginning_of_week - 1.week) }
    let(:non_internship_course) { FactoryBot.create(:course) }

    context 'adding new enrollments' do
      it 'updates starting & current cohort & start & end dates when adding first course' do
        student.save
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': current_cohort.description, 'custom.Start Date': current_cohort.start_date.to_s, 'custom.Cohort - Current': current_cohort.description, 'custom.End Date': current_cohort.end_date.to_s })
        student.course = current_cohort.courses.last
      end

      it 'updates only starting cohort and start date when adding second course from earlier cohort' do
        student.course = current_cohort.courses.first
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': past_cohort.description, 'custom.Start Date': past_cohort.start_date.to_s })
        student.course = past_cohort.courses.first
      end

      it 'updates only current cohort and end date when adding second course with later start date' do
        student.course = current_cohort.courses.first
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': current_cohort.description, 'custom.End Date': future_cohort.end_date.to_s })
        student.course = future_cohort.courses.last
      end

      it 'updates only part-time cohort when adding part-time course' do
        student.save
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Part-time': part_time_cohort.description })
        student.course = part_time_cohort.courses.first
      end

      it 'does not update starting or current cohort when adding non-internship course' do
        student.save
        expect_any_instance_of(CrmLead).to_not receive(:update)
        student.course = non_internship_course
      end

      it 'updates current cohort correctly when enrolling in internship course belonging to multiple cohorts' do
        future_cohort.courses.each { |course| student.courses << course }
        expect(student.cohort).to eq future_cohort
      end

      it 'updates ending cohort when adding full-time course' do
        student.course = current_cohort.courses.last
        expect(student.ending_cohort).to eq current_cohort
      end

      it 'updates ending cohort when adding part-time course' do
        student.course = part_time_cohort.courses.first
        expect(student.ending_cohort).to eq part_time_cohort
      end
    end

    context 'removing enrollments' do
      before do
        course = current_cohort.courses.last
        student.course = course
        FactoryBot.create(:attendance_record, student: student, date: course.start_date)
      end

      it 'updates current cohort only when just archiving enrollment' do
        student.courses = [past_cohort.courses.last]
        allow_any_instance_of(CrmLead).to receive(:update_internship_class)
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': nil, 'custom.End Date': nil })
        student.enrollments.destroy_all
      end

      it 'clears starting & current cohort when permanently removing the only enrollment' do
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': nil, 'custom.Start Date': nil, 'custom.Cohort - Current': nil, 'custom.End Date':nil })
        student.enrollments.first.really_destroy!
      end

      it 'updates only starting cohort when removing course from earlier cohort' do
        past_course = past_cohort.courses.first
        student.course = past_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Starting': current_cohort.description, 'custom.Start Date': current_cohort.start_date.to_s })
        student.enrollments.find_by(course: past_course).really_destroy!
      end

      it 'updates only current cohort when removing course from later cohort' do
        future_course = future_cohort.courses.first
        student.course = future_course
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': current_cohort.description, 'custom.End Date': current_cohort.end_date.to_s })
        student.enrollments.find_by(course: future_course).really_destroy!
      end

      it 'clears only current cohort when removing last internship course' do
        full_cohort_student = FactoryBot.create(:student_in_full_cohort)
        full_cohort = full_cohort_student.cohort
        expect_any_instance_of(CrmLead).to receive(:update).with({ 'custom.Cohort - Current': nil, 'custom.End Date': nil })
        full_cohort_student.enrollments.find_by(course: full_cohort.courses.last).really_destroy!
      end

      it 'does not clear ending cohort when removing course' do
        student.course = part_time_cohort.courses.first
        student.enrollments.first.destroy
        expect(student.cohort).to eq nil
        expect(student.ending_cohort).to eq part_time_cohort
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

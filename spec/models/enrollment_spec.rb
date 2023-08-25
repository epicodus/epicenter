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
    context 'before course start date' do
      it 'permanently destroys enrollment' do
        future_course = FactoryBot.create(:future_course)
        student = FactoryBot.create(:student, course: future_course)
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end
    end

    context 'within first week of course' do
      it 'permanently destroys enrollment' do
        student = FactoryBot.create(:student, :with_course)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
          enrollment = student.enrollments.first
          student.enrollments.first.destroy
          student.reload
          expect(student.enrollments.with_deleted).to eq []
        end
      end
    end

    context 'after first week of course' do
      let(:past_course) { FactoryBot.create(:past_course) }
      let(:future_course) { FactoryBot.create(:future_course) }
      let(:student) { FactoryBot.create(:student, course: past_course) }

      it 'archives enrollment with paranoia if attendance record exists' do
        FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end

      it 'permanently destroys enrollment if no attendance record exists' do
        student.enrollments.first.destroy
        expect(student.enrollments.with_deleted).to eq []
      end

      it 'archives internship course enrollment regardless of attendance' do
        student.courses = [FactoryBot.create(:past_internship_course)]
        enrollment = student.enrollments.first
        student.enrollments.first.destroy
        student.reload
        expect(student.enrollments).to eq []
        expect(student.enrollments.with_deleted).to eq [enrollment]
      end
    end
  end

  describe 'updates cohorts only when changes' do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:admin) { FactoryBot.create(:admin) }
    let(:past_cohort) { FactoryBot.create(:ft_cohort, start_date: (Date.today - 1.year).beginning_of_week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:current_cohort) { FactoryBot.create(:ft_cohort, start_date: Date.today.beginning_of_week - 1.week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:future_cohort) { FactoryBot.create(:ft_cohort, start_date: (Date.today + 1.year).beginning_of_week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:part_time_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Date.today.beginning_of_week - 1.week, office: office, admin: admin, track: FactoryBot.create(:part_time_track)) }
    let(:non_internship_course) { FactoryBot.create(:course, office: office) }
    let!(:student) { FactoryBot.create(:student, courses: []) }

    context 'adding new enrollments' do
      it 'updates starting & current cohort when adding full-time course' do
        student.courses = [current_cohort.courses.first]
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.courses << current_cohort.courses.last
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq current_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'updates parttime cohort when adding part-time intro course' do
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => nil,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => part_time_cohort.description
        }))
        student.courses = part_time_cohort.courses
        expect(student.starting_cohort).to eq nil
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq part_time_cohort
      end

      it 'updates starting & current cohort when adding full-time course after part-time course' do
        student.courses = [part_time_cohort.courses.first, future_cohort.courses.first]
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => future_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => future_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => part_time_cohort.description
        }))
        student.courses << future_cohort.courses.last
        expect(student.starting_cohort).to eq future_cohort
        expect(student.cohort).to eq future_cohort
        expect(student.parttime_cohort).to eq part_time_cohort
      end

      it 'updates only current cohort and parttime cohort when adding part-time course after withdrawn full-time course' do
        student.courses = current_cohort.courses
        student.attendance_records.create(date: student.course.start_date)
        student.enrollments.destroy_all
        student.reload
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => part_time_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil
        }))
        student.courses = part_time_cohort.courses
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq part_time_cohort
      end

      it 'updates only starting cohort when adding second full-time course from earlier cohort' do
        student.courses = current_cohort.courses
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] =>
          past_cohort.description, Rails.application.config.x.crm_fields['COHORT_CURRENT'] =>
          current_cohort.description, Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.course = past_cohort.courses.first
        expect(student.starting_cohort).to eq past_cohort
        expect(student.cohort).to eq current_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'updates only current cohort when adding second full-time course with later start date' do
        student.courses = current_cohort.courses
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => future_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.courses << future_cohort.courses
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq future_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'does not update current cohort when adding full-time non-internship course' do
        student.course = non_internship_course
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq nil
      end

      it 'updates current cohort correctly when enrolling in internship course belonging to multiple cohorts' do
        future_cohort.courses.each { |course| student.courses << course }
        expect(student.cohort).to eq future_cohort
        expect(student.starting_cohort).to eq future_cohort
        expect(student.cohort).to eq future_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'does not assign current cohort when no internship course present' do
        student.course = current_cohort.courses.first
        expect(student.cohort).to eq nil
      end

      it 'does not assign current cohort when only internship course present' do
        student.course = current_cohort.courses.last
        expect(student.cohort).to eq nil
      end

      it 'assigns current cohort when both internship course and another course present' do
        student.courses = current_cohort.courses
        expect(student.cohort).to eq current_cohort
      end
    end

    context 'removing enrollments' do
      it 'updates current cohort only when just archiving enrollment' do
        student.courses = past_cohort.courses
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => past_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.enrollments.destroy_all
        expect(student.starting_cohort).to eq past_cohort
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq nil
      end

      it 'clears starting & current cohort when permanently removing the only enrollment' do
        student.courses = current_cohort.courses
        student.courses = [current_cohort.courses.last]
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => nil,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.enrollments.destroy_all
        expect(student.starting_cohort).to eq nil
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq nil
      end

      it 'updates only starting cohort when removing course from earlier cohort' do
        student.courses = current_cohort.courses
        past_course = past_cohort.courses.first
        student.course = past_course
        expect(student.starting_cohort).to eq past_cohort
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.enrollments.find_by(course: past_course).really_destroy!
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq current_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'updates only current cohort when removing course from later cohort' do
        student.courses << [current_cohort.courses.first, current_cohort.courses.last, future_cohort.courses.first, future_cohort.courses.last]
        expect(student.crm_lead).to receive(:update).with(hash_including({ 
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.enrollments.find_by(course: future_cohort.courses.first).really_destroy!
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq current_cohort
        expect(student.parttime_cohort).to eq nil
      end

      it 'clears only current cohort when removing last internship course' do
        student.courses = current_cohort.courses
        expect(student.crm_lead).to receive(:update).with(hash_including({
          Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil,
          Rails.application.config.x.crm_fields['COHORT_STARTING'] => current_cohort.description,
          Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => nil
        }))
        student.enrollments.find_by(course: current_cohort.courses.last).really_destroy!
        expect(student.starting_cohort).to eq current_cohort
        expect(student.cohort).to eq nil
        expect(student.parttime_cohort).to eq nil
      end
    end
  end

  describe 'updating transfers count in CRM' do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:admin) { FactoryBot.create(:admin) }
    let(:past_cohort) { FactoryBot.create(:ft_cohort, start_date: (Date.today - 1.year).beginning_of_week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:current_cohort) { FactoryBot.create(:ft_cohort, start_date: Date.today.beginning_of_week - 1.week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:future_cohort) { FactoryBot.create(:ft_cohort, start_date: (Date.today + 1.year).beginning_of_week, office: office, admin: admin, track: FactoryBot.create(:track)) }
    let(:part_time_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Date.today.beginning_of_week - 1.week, office: office, admin: admin, track: FactoryBot.create(:part_time_track)) }
    let!(:student) { FactoryBot.create(:student, courses: []) }
  
    context 'updates transfers count correctly when' do
      it 'adding fulltime course' do
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 0 }))
        student.course = current_cohort.courses.first
      end

      it 'adding second fulltime course' do
        student.course = current_cohort.courses.first
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 1 }))
        student.courses << future_cohort.courses.first
      end

      it 'adding parttime course' do
        student.course = current_cohort.courses.first
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 0 }))
        student.course = part_time_cohort.courses.first
      end

      it 'removing past fulltime course with attendance record' do
        student.courses = [past_cohort.courses.first, current_cohort.courses.first]
        student.attendance_records.create(date: student.courses.first.start_date)
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 1 }))
        Enrollment.find_by(student: student, course: past_cohort.courses.first).destroy
      end

      it 'removing past fulltime course without attendance record' do
        student.courses = [past_cohort.courses.first, current_cohort.courses.first]
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 0 }))
        Enrollment.find_by(student: student, course: past_cohort.courses.first).destroy
      end

      it 'removing pasttime course' do
        student.courses = [part_time_cohort.courses.first, current_cohort.courses.first]
        expect_any_instance_of(CrmLead).to receive(:update).with(hash_including({ Rails.application.config.x.crm_fields['TRANSFERS'] => 0 }))
        Enrollment.find_by(student: student, course: part_time_cohort.courses.first).destroy
      end
    end
  end

  describe 'internship class in CRM', :dont_stub_update_internship_class do
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

  describe '#clear_submissions' do
    it 'clears submissions for withdrawn course' do
      student = FactoryBot.create(:student, :with_course)
      code_review = FactoryBot.create(:code_review, course: student.course)
      submission = FactoryBot.create(:submission, student: student, code_review: code_review)
      student.enrollments.first.destroy
      expect(submission.reload.needs_review).to eq false
    end

    it 'does not clear submissions for a different course' do
      student = FactoryBot.create(:student, :with_course)
      other_course = FactoryBot.create(:course)
      code_review = FactoryBot.create(:code_review, course: other_course)
      submission = FactoryBot.create(:submission, student: student, code_review: code_review)
      student.enrollments.first.destroy
      expect(submission.reload.needs_review).to eq true
    end
  end
end

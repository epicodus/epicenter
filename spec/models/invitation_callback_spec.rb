describe InvitationCallback, :dont_stub_crm, :vcr do
  let(:student) { FactoryBot.create(:student) }

  before do
    allow(CrmUpdateJob).to receive(:perform_later).and_return({})
    allow_any_instance_of(Closeio::Client).to receive(:create_task).and_return({})
  end

  context 'when conditions not met' do
    it 'raises error if no lead found with matching email' do
      expect { InvitationCallback.new(email: 'does_not_exist_in_close@example.com') }.to raise_error(CrmError, "The Close.io lead for does_not_exist_in_close@example.com was not found.")
    end

    it 'expunges existing user if no payments or attendance records' do
      cohort = FactoryBot.create(:ft_cohort, start_date: Date.parse('2000-01-03'))
      FactoryBot.create(:student, email: 'example@example.com')
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(cohort.description)
      expect_any_instance_of(Student).to receive(:really_destroy)
      InvitationCallback.new(email: 'example@example.com')
    end

    it 'creates task on CRM lead if email already found in Epicenter and student has attendance record' do
      student = FactoryBot.create(:student, :with_course, email: 'example@example.com')
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      expect_any_instance_of(CrmLead).to receive(:create_task).with('Unable to invite due to existing Epicenter account')
      InvitationCallback.new(email: 'example@example.com')
    end

    it 'creates task on CRM lead if email already found in Epicenter and student has payment' do
      student = FactoryBot.create(:student, :with_ft_cohort, :with_upfront_payment, email: 'example@example.com')
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(student.cohort.description)
      expect_any_instance_of(CrmLead).to receive(:create_task).with('Unable to invite due to existing Epicenter account')
      InvitationCallback.new(email: 'example@example.com')
    end

    it 'raises error if cohort not found in Epicenter' do
      FactoryBot.create(:track, description: 'C#/React')
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return('2000-01-03 to 2000-02-13 C#/React')
      expect { InvitationCallback.new(email: 'example-invalid-cohort@example.com') }.to raise_error(CrmError, "Cohort not found in Epicenter")
    end
  end

  context 'for part-time students' do
    let!(:part_time_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Date.parse('2000-01-03')) }
    let!(:parttime_plan) { FactoryBot.create(:parttime_plan) }

    describe 'creates epicenter account' do
      before do
        allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(part_time_cohort.description)
        InvitationCallback.new(email: 'example-part-time@example.com')
      end

      it 'sets student name' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
      end

      it 'does not set starting cohort' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.starting_cohort).to eq nil
      end

      it 'does not set current cohort' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.cohort).to eq nil
      end

      it 'sets parttime cohort' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.parttime_cohort).to eq part_time_cohort
      end

      it 'assigns correct course' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.courses.count).to eq 1
        expect(student.course).to eq part_time_cohort.courses.first
      end

      it 'assigns part-time payment plan' do
        student = Student.find_by(email: 'example-part-time@example.com')
        expect(student.plan).to eq parttime_plan
      end
    end
  end

  context 'for full-time students' do
    let!(:cohort) { FactoryBot.create(:ft_full_cohort, start_date: Date.parse('2000-01-03')) }

    describe 'creates epicenter account' do
      before do
        allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(cohort.description)
        InvitationCallback.new(email: 'example@example.com')
      end

      it 'sets student name' do
        student = Student.find_by(email: 'example@example.com')
        expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
      end

      it 'sets cohort' do
        student = Student.find_by(email: 'example@example.com')
        expect(student.cohort).to eq cohort
      end

      it 'sets starting cohort' do
        student = Student.find_by(email: 'example@example.com')
        expect(student.starting_cohort).to eq cohort
      end

      it 'assigns correct courses' do
        student = Student.find_by(email: 'example@example.com')
        expect(student.courses.count).to eq 5
        expect(student.courses.first).to eq cohort.courses.first
      end

      it 'does not assign payment plan' do
        student = Student.find_by(email: 'example@example.com')
        expect(student.plan).to eq nil
      end
    end
  end

  context 'for part-time full-stack students' do
    let!(:cohort) { FactoryBot.create(:pt_c_react_cohort, start_date: Date.parse('2000-01-03')) }

    describe 'creates epicenter account' do
      before do
        allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(cohort.description)
        InvitationCallback.new(email: 'example-part-time-full-stack@example.com')
      end

      it 'sets student name' do
        student = Student.find_by(email: 'example-part-time-full-stack@example.com')
        expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
      end

      it 'sets cohort' do
        student = Student.find_by(email: 'example-part-time-full-stack@example.com')
        expect(student.cohort).to eq cohort
      end

      it 'sets starting cohort' do
        student = Student.find_by(email: 'example-part-time-full-stack@example.com')
        expect(student.starting_cohort).to eq cohort
      end

      it 'assigns correct courses' do
        student = Student.find_by(email: 'example-part-time-full-stack@example.com')
        expect(student.courses.count).to eq 5
        expect(student.courses.order(:id)).to eq cohort.courses.order(:id)
      end

      it 'does not assign payment plan' do
        student = Student.find_by(email: 'example-part-time-full-stack@example.com')
        expect(student.plan).to eq nil
      end
    end
  end

  context 'creates Epicenter account for Fidgetech students' do
    let!(:fidgetech_cohort) { FactoryBot.create(:fidgetech_cohort) }
    let!(:special_plan) {FactoryBot.create(:special_plan) }

    describe 'creates epicenter account' do
      before do
        InvitationCallback.new(email: 'example-fidgetech@example.com')
      end

      it 'sets student name' do
        student = Student.find_by(email: 'example-fidgetech@example.com')
        expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
      end

      it 'sets cohort' do
        student = Student.find_by(email: 'example-fidgetech@example.com')
        expect(student.parttime_cohort).to eq fidgetech_cohort
      end

      it 'sets starting cohort' do
        student = Student.find_by(email: 'example-fidgetech@example.com')
        expect(student.parttime_cohort).to eq fidgetech_cohort
      end

      it 'assigns correct course' do
        student = Student.find_by(email: 'example-fidgetech@example.com')
        expect(student.courses.count).to eq 1
        expect(student.course).to eq fidgetech_cohort.courses.first
      end

      it 'assign special payment plan' do
        student = Student.find_by(email: 'example-fidgetech@example.com')
        expect(student.plan).to eq special_plan
      end
    end
  end

  it 'does not enroll international students in internship course' do
    cohort = FactoryBot.create(:ft_full_cohort, start_date: Date.parse('2000-01-03'))
    internship_exempt_course = FactoryBot.create(:internship_course, description: 'Internship Exempt', track: cohort.track)
    allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(cohort.description)
    InvitationCallback.new(email: 'example-international@example.com')
    student = Student.find_by(email: 'example-international@example.com')
    expect(student.courses.count).to eq 5
    expect(student.courses.last).to eq internship_exempt_course
  end

  it 'updates CRM status after creating student account with invitation token and student id' do
    part_time_cohort = FactoryBot.create(:pt_intro_cohort, start_date: Date.parse('2000-01-03'))
    allow_any_instance_of(Enrollment).to receive(:update_cohort).and_return({})
    expect_any_instance_of(CrmLead).to receive(:update_now).with(hash_including(Rails.application.config.x.crm_fields['INVITATION_TOKEN'], Rails.application.config.x.crm_fields['EPICENTER_ID']))
    allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(part_time_cohort.description)
    InvitationCallback.new(email: 'example-part-time@example.com')
  end
end
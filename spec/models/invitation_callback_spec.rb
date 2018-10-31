describe InvitationCallback, :dont_stub_crm, :vcr do
  let(:student) { FactoryBot.create(:student) }

  before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

  context 'when conditions not met' do
    it 'raises error if no lead found with matching email' do
      expect { InvitationCallback.new(email: 'does_not_exist_in_close@example.com') }.to raise_error(CrmError, "Invitation callback: unique CRM lead not found for does_not_exist_in_close@example.com")
    end

    it 'expunges existing user if no payments or attendance records' do
      FactoryBot.create(:intro_only_cohort, start_date: Date.parse('2000-01-03'))
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect { InvitationCallback.new(email: 'example@example.com') }.to_not raise_error
      expect(User.exists?(student.id)).to eq false
    end

    it 'raises error if email already found in Epicenter and student can not be expunged' do
      student = FactoryBot.create(:student, email: 'example@example.com')
      FactoryBot.create(:attendance_record, student: student)
      expect { InvitationCallback.new(email: 'example@example.com') }.to raise_error(CrmError, "Invitation callback: example@example.com already exists in Epicenter")
    end

    it 'raises error if cohort not found in Epicenter' do
      FactoryBot.create(:track)
      expect { InvitationCallback.new(email: 'example-invalid-cohort@example.com') }.to raise_error(CrmError, "Cohort not found in Epicenter")
    end
  end

  context 'creates Epicenter account for part-time students' do
    let!(:part_time_cohort) { FactoryBot.create(:part_time_cohort, start_date: Date.parse('2000-01-03')) }
    let!(:parttime_plan) { FactoryBot.create(:parttime_plan) }

    before do
      InvitationCallback.new(email: 'example-part-time@example.com')
    end

    it 'sets student name' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
    end

    it 'sets part-time cohort' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.parttime_cohort).to eq part_time_cohort
    end

    it 'sets ending cohort' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.ending_cohort).to eq part_time_cohort
    end

    it 'does not set cohort' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.cohort).to eq nil
    end

    it 'does not set starting cohort' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.starting_cohort).to eq nil
    end

    it 'assigns correct course' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.courses.count).to eq 1
      expect(student.course).to eq part_time_cohort.courses.first
    end

    it 'assigns office' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.office).to eq part_time_cohort.courses.first.office
    end

    it 'assigns part-time payment plan' do
      student = Student.find_by(email: 'example-part-time@example.com')
      expect(student.plan).to eq parttime_plan
    end
  end

  context 'creates Epicenter account for full-time students' do
    let!(:cohort) { FactoryBot.create(:full_cohort, start_date: Date.parse('2000-01-03')) }

    before do
      InvitationCallback.new(email: 'example@example.com')
    end

    it 'sets student name' do
      student = Student.find_by(email: 'example@example.com')
      expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
    end

    it 'does not set part-time cohort' do
      student = Student.find_by(email: 'example@example.com')
      expect(student.parttime_cohort).to eq nil
    end

    it 'sets ending cohort' do
      student = Student.find_by(email: 'example@example.com')
      expect(student.ending_cohort).to eq cohort
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

    it 'assigns office' do
      student = Student.find_by(email: 'example@example.com')
      expect(student.office).to eq cohort.courses.first.office
    end

    it 'does not assign payment plan' do
      student = Student.find_by(email: 'example@example.com')
      expect(student.plan).to eq nil
    end
  end

  context 'creates Epicenter account for Fidgetech students' do
    let!(:fidgetech_cohort) { FactoryBot.create(:fidgetech_cohort) }
    let!(:special_plan) {FactoryBot.create(:special_plan) }

    before do
      InvitationCallback.new(email: 'example-fidgetech@example.com')
    end

    it 'sets student name' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
    end

    it 'does not set part-time cohort' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.parttime_cohort).to eq nil
    end

    it 'does not set ending cohort' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.ending_cohort).to eq nil
    end

    it 'does not set cohort' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.cohort).to eq nil
    end

    it 'sets starting cohort' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.starting_cohort).to eq fidgetech_cohort
    end

    it 'assigns correct course' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.courses.count).to eq 1
      expect(student.course).to eq fidgetech_cohort.courses.first
    end

    it 'assigns office' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.office).to eq fidgetech_cohort.courses.first.office
    end

    it 'assign special payment plan' do
      student = Student.find_by(email: 'example-fidgetech@example.com')
      expect(student.plan).to eq special_plan
    end
  end

  it 'does not enroll international students in internship course' do
    internship_exempt_course = FactoryBot.create(:internship_course, description: 'Internship Exempt')
    cohort = FactoryBot.create(:full_cohort, start_date: Date.parse('2000-01-03'))
    InvitationCallback.new(email: 'example-international@example.com')
    student = Student.find_by(email: 'example-international@example.com')
    expect(student.courses.count).to eq 5
    expect(student.courses.last).to eq internship_exempt_course
  end

  it 'updates CRM status after creating student account with invitation token and student id' do
    part_time_cohort = FactoryBot.create(:part_time_cohort, start_date: Date.parse('2000-01-03'))
    allow_any_instance_of(Enrollment).to receive(:update_cohort).and_return({})
    expect_any_instance_of(CrmLead).to receive(:update).with(hash_including(:"custom.Epicenter - Raw Invitation Token", :"custom.Epicenter - ID"))
    InvitationCallback.new(email: 'example-part-time@example.com')
  end
end

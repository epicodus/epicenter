describe InvitationCallback, :dont_stub_crm, :vcr do
  let(:student) { FactoryBot.create(:student) }

  before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

  it 'raises error if no lead found with matching email' do
    expect { InvitationCallback.new(email: 'does_not_exist_in_close@example.com') }.to raise_error(CrmError, "Invitation callback: unique CRM lead not found for does_not_exist_in_close@example.com")
  end

  it 'raises error if email already found in Epicenter' do
    FactoryBot.create(:student, email: 'example@example.com')
    expect { InvitationCallback.new(email: 'example@example.com') }.to raise_error(CrmError, "Invitation callback: example@example.com already exists in Epicenter")
  end

  it 'raises error if cohort not found in Epicenter' do
    FactoryBot.create(:track)
    expect { InvitationCallback.new(email: 'example-invalid-cohort@example.com') }.to raise_error(CrmError, "Cohort not found in Epicenter")
  end

  it 'creates Epicenter account for full-time student if email found in CRM' do
    cohort = FactoryBot.create(:full_cohort, start_date: Date.parse('2000-01-03'))
    InvitationCallback.new(email: 'example@example.com')
    student = Student.find_by(email: 'example@example.com')
    expect(student.cohort).to eq cohort
    expect(student.starting_cohort).to eq cohort
    expect(student.parttime_cohort).to eq nil
    expect(student.ending_cohort).to eq cohort
    expect(student.courses.count).to eq 5
    expect(student.courses.first).to eq cohort.courses.first
    expect(student.office).to eq cohort.courses.first.office
    expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
  end

  it 'creates Epicenter account for part-time student if email found in CRM' do
    part_time_cohort = FactoryBot.create(:part_time_cohort, start_date: Date.parse('2000-01-03'))
    InvitationCallback.new(email: 'example-part-time@example.com')
    student = Student.find_by(email: 'example-part-time@example.com')
    expect(student.cohort).to eq nil
    expect(student.starting_cohort).to eq nil
    expect(student.parttime_cohort).to eq part_time_cohort
    expect(student.ending_cohort).to eq part_time_cohort
    expect(student.courses.count).to eq 1
    expect(student.course).to eq part_time_cohort.courses.first
    expect(student.office).to eq part_time_cohort.courses.first.office
    expect(student.name).to eq 'THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE.'
  end

  it 'updates CRM status after creating student account' do
    part_time_cohort = FactoryBot.create(:part_time_cohort, start_date: Date.parse('2000-01-03'))
    allow_any_instance_of(Enrollment).to receive(:update_cohort).and_return({})
    expect_any_instance_of(CrmLead).to receive(:update).with(hash_including(:"custom.Epicenter - Raw Invitation Token"))
    InvitationCallback.new(email: 'example-part-time@example.com')
  end
end

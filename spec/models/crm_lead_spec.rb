describe CrmLead, :dont_stub_crm do
  describe '#initialize', :vcr do
    it 'raises error if lead not found' do
      expect { CrmLead.new('does_not_exist@example.com').status }.to raise_error(CrmError, "The Close.io lead for does_not_exist@example.com was not found.")
    end
  end

  describe '#status', :vcr do
    it 'returns lead status' do
      expect(CrmLead.new('example@example.com').status).to eq "Applicant - No longer interested (legacy)"
    end
  end

  describe '#name', :vcr do
    it 'returns lead name' do
      expect(CrmLead.new('example@example.com').name).to eq "THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE."
    end
  end

  describe '#cohort', :vcr do
    it 'returns cohort for full-time student' do
      cohort = FactoryBot.create(:intro_only_cohort, start_date: Date.parse('2000-01-03'))
      expect(CrmLead.new('example@example.com').cohort).to eq cohort
    end

    it 'returns Fidgetech cohort' do
      cohort = FactoryBot.create(:intro_only_cohort, description: 'Fidgetech')
      expect(CrmLead.new('example-fidgetech@example.com').cohort).to eq cohort
    end

    it 'raises error if cohort does not exist in Epicenter' do
      FactoryBot.create(:track)
      expect { CrmLead.new('example@example.com').cohort }.to raise_error(CrmError, "Cohort not found in Epicenter")
    end

    it 'returns nil for part-time student' do
      expect(CrmLead.new('example-part-time@example.com').cohort).to eq nil
    end
  end

  describe '#first_course', :vcr do
    it 'for full-time student' do
      cohort = FactoryBot.create(:intro_only_cohort, start_date: Date.parse('2000-01-03'))
      expect(CrmLead.new('example@example.com').first_course).to eq cohort.courses.first
    end

    it 'for part-time student' do
      course = FactoryBot.create(:part_time_course, class_days: [Date.parse('2000-01-03')], office: FactoryBot.create(:philadelphia_office))
      expect(CrmLead.new('example-part-time@example.com').first_course).to eq course
    end

    it 'for fidgetech student' do
      course = FactoryBot.create(:course, description: 'Fidgetech')
      cohort = FactoryBot.create(:intro_only_cohort, description: 'Fidgetech')
      cohort.courses = [course]
      expect(CrmLead.new('example-fidgetech@example.com').first_course).to eq course
    end

    it 'raises error if course does not exist in Epicenter' do
      FactoryBot.create(:track)
      expect { CrmLead.new('example-part-time@example.com').first_course }.to raise_error(CrmError, "Course not found in Epicenter")
    end
  end

  describe '#update_internship_class', :vcr do
    let!(:student) { FactoryBot.create(:student, email: "example@example.com", courses: []) }

    it 'updates internship class field in CRM' do
      internship_course = FactoryBot.create(:internship_course)
      description = "#{internship_course.office.short_name} #{internship_course.description.split.first} #{internship_course.start_date.strftime('%b %-d')} - #{internship_course.end_date.strftime('%b %-d')}"
      expect_any_instance_of(CrmLead).to receive(:update).with({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => description })
      student.crm_lead.update_internship_class(internship_course)
    end

    it 'clears internship class field in CRM if no course passed in' do
      expect_any_instance_of(CrmLead).to receive(:update).with({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => nil })
      student.crm_lead.update_internship_class(nil)
    end
  end

  describe 'updating close.io when student email is updated', :vcr do
    let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'updates the record successfully' do
      expect(CrmUpdateJob).to receive(:perform_later).with(ENV['EXAMPLE_CRM_LEAD_ID'], { email: "second-email@example.com" })
      student.crm_lead.update(email: "second-email@example.com")
    end

    it 'does not update the record when the email is not found' do
      student = FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com')
      student.update(email: "no_close_entry@example.com")
      expect { student.crm_lead.update(email: "second-email@example.com") }.to raise_error(CrmError, "The Close.io lead for #{student.email} was not found.")
    end
  end

  describe 'adding note to close.io', :vcr do
    let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { get_lead_id(student.email) }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'adds a note successfully' do
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "test note from api" })
      student.crm_lead.update(note: "test note from api")
    end
  end
end

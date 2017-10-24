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
      cohort = FactoryBot.create(:cohort, start_date: Date.parse('2000-01-03'))
      expect(CrmLead.new('example@example.com').cohort).to eq cohort
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
      cohort = FactoryBot.create(:cohort, start_date: Date.parse('2000-01-03'))
      expect(CrmLead.new('example@example.com').first_course).to eq cohort.courses.first
    end

    it 'for part-time student' do
      course = FactoryBot.create(:part_time_course, class_days: [Date.parse('2000-01-03')], office: FactoryBot.create(:philadelphia_office))
      expect(CrmLead.new('example-part-time@example.com').first_course).to eq course
    end

    it 'raises error if course does not exist in Epicenter' do
      FactoryBot.create(:track)
      expect { CrmLead.new('example-part-time@example.com').first_course }.to raise_error(CrmError, "Course not found in Epicenter")
    end
  end

  describe '#update_internship_class', :vcr do
    let(:student) { FactoryBot.create(:student, courses: []) }

    it 'updates internship class field in CRM' do
      internship_course = FactoryBot.create(:internship_course)
      location = internship_course.office.name
      location = 'PDX' if location == 'Portland'
      location = 'SEA' if location == 'Seattle'
      description = "#{location} #{internship_course.description.split.first} #{internship_course.start_date.strftime('%b %-d')} - #{internship_course.end_date.strftime('%b %-d')}"
      expect_any_instance_of(CrmLead).to receive(:update).with({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => description })
      student.crm_lead.update_internship_class(internship_course)
    end

    it 'clears internship class field in CRM if no course passed in' do
      expect_any_instance_of(CrmLead).to receive(:update).with({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => nil })
      student.crm_lead.update_internship_class(nil)
    end
  end

  describe 'updating close.io when student email is updated' do
    let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:contact_id) { close_io_client.list_leads('email:' + student.email).data.first.contacts.first.id }

    before do
      allow_any_instance_of(CrmLead).to receive(:close_io_client).and_return(close_io_client)
    end

    it 'updates the record successfully', :vcr do
      allow(close_io_client).to receive(:update_contact).and_return({})
      old_entry = Hashie::Mash.new({ type: "office", email: student.email })
      new_entry = Hashie::Mash.new({ type: "office", email: "second-email@example.com" })
      expect(close_io_client).to receive(:update_contact).with(contact_id, { 'emails': [new_entry, old_entry] })
      student.crm_lead.update(email: new_entry.email)
    end

    it 'does not update the record when the email is not found', :vcr do
      student.update(email: "no_close_entry@example.com")
      expect { student.crm_lead.update(email: "second-email@example.com") }.to raise_error(CrmError, "The Close.io lead for #{student.email} was not found.")
    end

    it 'raises an error when the new email is invalid', :vcr do
      allow(close_io_client).to receive(:update_contact).and_return({"errors"=>[], "field-errors"=>{"emails"=>{"errors"=>{"0"=>{"errors"=>[], "field-errors"=>{"email"=>"Invalid email address."}}}}}})
      expect { student.crm_lead.update(email: "invalid@invalid") }.to raise_error(CrmError, 'Invalid email address.')
    end
  end
end

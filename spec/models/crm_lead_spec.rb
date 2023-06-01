describe CrmLead, :dont_stub_crm, :vcr do
  before do
    allow_any_instance_of(Closeio::Client).to receive(:create_task).and_return({})
  end

  describe '#initialize' do
    it 'raises error if lead not found' do
      expect { CrmLead.new('does_not_exist@example.com').status }.to raise_error(CrmError, "The Close.io lead for does_not_exist@example.com was not found.")
    end
  end

  describe '.lead_exists?' do
    it 'returns true if unique lead exists' do
      expect(CrmLead.lead_exists?('example@example.com')).to eq true
    end
    it 'returns false if lead does not exist' do
      expect(CrmLead.lead_exists?('lead_does_not_exist_in_close@example.com')).to eq false
    end
    it 'returns false if duplicate lead exists' do
      allow_any_instance_of(Closeio::Client).to receive(:list_leads).and_return({ 'total_results' => 2 })
      expect(CrmLead.lead_exists?('example@example.com')).to eq false
    end
  end

  describe '#status' do
    it 'returns lead status' do
      expect(CrmLead.new('example@example.com').status).to eq "Applicant - Declined - Not Interested (legacy)"
    end
  end

  describe '#name' do
    it 'returns lead name' do
      expect(CrmLead.new('example@example.com').name).to eq "THIS LEAD IS USED FOR TESTING PURPOSES. PLEASE DO NOT DELETE."
    end
  end

  describe '#pronouns' do
    it 'returns lead pronouns' do
      expect(CrmLead.new('example@example.com').pronouns).to eq "they / them"
    end
  end

  describe '#cohort' do
    it 'returns cohort for full-time student' do
      cohort = FactoryBot.create(:ft_cohort, start_date: Date.parse('2000-01-03'))
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return('2000-01-03 to 2000-03-02 C#/React')
      expect(CrmLead.new('example@example.com').cohort).to eq cohort
    end

    it 'returns cohort for part-time intro student' do
      cohort = FactoryBot.create(:pt_intro_cohort, start_date: Date.parse('2000-01-03'))
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return('2000-01-03 to 2000-04-12 Part-Time Intro to Programming')
      expect(CrmLead.new('example-part-time@example.com').cohort).to eq cohort
    end

    it 'returns Fidgetech cohort' do
      cohort = FactoryBot.create(:fidgetech_cohort)
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return('Fidgetech')
      expect(CrmLead.new('example-fidgetech@example.com').cohort).to eq cohort
    end

    it 'raises error if cohort does not exist in Epicenter' do
      FactoryBot.create(:track)
      allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return('2000-01-03 to 2000-03-02 C#/React')
      expect { CrmLead.new('example@example.com').cohort }.to raise_error(CrmError, "Cohort not found in Epicenter")
    end
  end

  describe '#work_eligible?' do
    it 'returns true if student is work eligible' do
      expect(CrmLead.new('example@example.com').work_eligible?).to eq true
    end

    it 'returns false if student is work eligible' do
      expect(CrmLead.new('example-international@example.com').work_eligible?).to eq false
    end
  end

  describe '#career_services_contact' do
    it 'returns career serices contact user id' do
      expect(CrmLead.new('example@example.com').career_services_contact).to eq ENV['EXAMPLE_CRM_CAREER_SERVICES_CONTACT_ID']
    end
  end

  describe '#state' do
    it 'returns state of first address of lead' do
      expect(CrmLead.new('washington@example.com').state).to eq 'WA'
    end
  end

  describe '#contact_id' do
    it 'returns contact_id if present in CRM' do
      expect(CrmLead.new('example@example.com').contact_id).to include 'cont_'
    end
  end

  describe '#create_task' do
    it 'creates task' do
      crm_lead = CrmLead.new('example@example.com')
      allow_any_instance_of(Closeio::Client).to receive(:create_task).and_return({})
      expect_any_instance_of(Closeio::Client).to receive(:create_task)
      crm_lead.create_task('test task')
    end
  end

  describe '#update' do
    it 'adds CRM update job to queue' do
      allow(CrmUpdateJob).to receive(:perform_later)
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmUpdateJob).to receive(:perform_later)
      student.crm_lead.update({'test': 'test'})
    end
  end

  describe '#update_now' do
    it 'calls perform_update (skips queue)' do
      allow(CrmLead).to receive(:perform_update)
      student = FactoryBot.create(:student, email: 'example@example.com')
      expect(CrmLead).to receive(:perform_update)
      student.crm_lead.update_now({'test': 'test'})
    end
  end

  describe '#update_internship_class', :dont_stub_update_internship_class do
    let!(:student) { FactoryBot.create(:student, email: "example@example.com", courses: []) }

    it 'updates internship class field in CRM' do
      internship_course = FactoryBot.create(:internship_course)
      description = "#{internship_course.office.short_name} #{internship_course.description.split.first} #{internship_course.start_date.strftime('%b %-d')} - #{internship_course.end_date.strftime('%b %-d')}"
      expect_any_instance_of(CrmLead).to receive(:update).with({ Rails.application.config.x.crm_fields['INTERNSHIP_CLASS'] => description })
      student.crm_lead.update_internship_class(internship_course)
    end

    it 'clears internship class field in CRM if no course passed in' do
      expect_any_instance_of(CrmLead).to receive(:update).with({ Rails.application.config.x.crm_fields['INTERNSHIP_CLASS'] => nil })
      student.crm_lead.update_internship_class(nil)
    end
  end

  describe 'updating close.io when student email is updated' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'updates the record successfully' do
      expect(CrmUpdateJob).to receive(:perform_later).with(ENV['EXAMPLE_CRM_LEAD_ID'], { email: "second-email@example.com" })
      student.crm_lead.update(email: "second-email@example.com")
    end

    it 'does not update the record when the email is not found' do
      student = FactoryBot.create(:student, :with_all_documents_signed, email: 'example@example.com')
      student.update(email: "no_close_entry@example.com")
      expect { student.crm_lead.update(email: "second-email@example.com") }.to raise_error(CrmError, "The Close.io lead for #{student.email} was not found.")
    end
  end

  describe 'adding note to close.io' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { get_lead_id(student.email) }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'adds a note successfully' do
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { note: "test note from api" })
      student.crm_lead.update(note: "test note from api")
    end
  end
end

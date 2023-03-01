describe DemographicInfo do
  it { should validate_presence_of :address }
  it { should validate_presence_of :city }
  it { should validate_presence_of :state }
  it { should validate_presence_of :zip }
  it { should validate_presence_of :country }
  it { should validate_length_of(:address).is_at_most(200) }
  it { should validate_length_of(:city).is_at_most(100) }
  it { should validate_length_of(:state).is_at_most(100) }
  it { should validate_length_of(:zip).is_at_most(10) }
  it { should validate_length_of(:country).is_at_most(100) }
  it { should validate_inclusion_of(:disability).in_array(["Yes", "No"]) }
  it { should validate_inclusion_of(:veteran).in_array(["Yes", "No"]) }
  it { should validate_inclusion_of(:cs_degree).in_array(["Yes", "No"]) }
  it { should validate_length_of(:job).is_at_most(35) }
  it { should validate_numericality_of(:ssn).is_less_than(1000000000) }

  it 'validates birth date is valid format' do
    demographic_info = FactoryBot.build(:demographic_info, birth_date: 'invalid')
    expect(demographic_info).to_not be_valid
  end

  it 'validates birth date is valid date' do
    demographic_info = FactoryBot.build(:demographic_info, birth_date: '2000-50-50')
    expect(demographic_info).to_not be_valid
  end

  it 'validates birth date is before today' do
    demographic_info = FactoryBot.build(:demographic_info, birth_date: '12/12/9999')
    expect(demographic_info).to_not be_valid
  end

  it 'accepts valid input' do
    demographic_info = FactoryBot.build(:demographic_info)
    expect(demographic_info).to be_valid
  end

  # it { should validate_numericality_of(:salary).is_greater_than_or_equal_to(0).with_message("must be greater than or equal to 0") }
  it 'validates salary is greater than or equal to 0' do # test written out due to bug in greater_than_or_equal_to shoulda matcher
    demographic_info = FactoryBot.build(:demographic_info, salary: -1)
    expect(demographic_info).to_not be_valid
  end

  it 'validates that gender form input is included in list' do
    demographic_info = FactoryBot.build(:demographic_info, genders: ['not in list'])
    expect(demographic_info).to_not be_valid
  end

  it 'validates that race form input is included in list' do
    demographic_info = FactoryBot.build(:demographic_info, races: ['not in list'])
    expect(demographic_info).to_not be_valid
  end

  it 'validates that education input is included in list' do
    demographic_info = FactoryBot.build(:demographic_info, education: 'not in list')
    expect(demographic_info).to_not be_valid
  end

  it 'validates that shirt size input is included in list' do
    demographic_info = FactoryBot.build(:demographic_info, shirt: 'not in list')
    expect(demographic_info).to_not be_valid
  end

  context 'validates after graduation input' do
    it 'is included in list' do
      demographic_info = FactoryBot.build(:demographic_info, after_graduation: 'not in list')
      expect(demographic_info).to_not be_valid
    end

    it 'with invalid time off input' do
      demographic_info = FactoryBot.build(:demographic_info, after_graduation: DemographicInfo::AFTER_OPTIONS[0], time_off: nil)
      expect(demographic_info).to_not be_valid
    end

    it 'with valid time off input' do
      demographic_info = FactoryBot.build(:demographic_info, after_graduation: DemographicInfo::AFTER_OPTIONS[0], time_off: 'No')
      expect(demographic_info).to be_valid
    end
  end

  describe 'updating close.io with demographics info', :vcr, :dont_stub_crm do
    let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { get_lead_id(student.email) }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'updates the record successfully' do
      demographic_info = FactoryBot.build(:demographic_info, :genders=>["Female"], :pronouns=>["they / them / their"], :job=>"test occupation", :salary=>15000, :races=>["Asian or Asian American"], student: student)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, {
        Rails.application.config.x.crm_fields['DEMOGRAPHICS_GENDER'] => demographic_info.genders.join(", "), Rails.application.config.x.crm_fields['DEMOGRAPHICS_PRONOUNS'] => demographic_info.pronouns.join(", "), Rails.application.config.x.crm_fields['DEMOGRAPHICS_AFTER_GRADUATION'] => demographic_info.after_graduation, Rails.application.config.x.crm_fields['DEMOGRAPHICS_BIRTH_DATE'] => demographic_info.birth_date, Rails.application.config.x.crm_fields['DEMOGRAPHICS_EDUCATION'] => demographic_info.education, Rails.application.config.x.crm_fields['DEMOGRAPHICS_DEGREE'] => demographic_info.cs_degree, Rails.application.config.x.crm_fields['DEMOGRAPHICS_SHIRT'] => demographic_info.shirt, Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_JOB'] => demographic_info.job, Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_SALARY'] => demographic_info.salary, Rails.application.config.x.crm_fields['DEMOGRAPHICS_RACE'] => demographic_info.races.join(', '), Rails.application.config.x.crm_fields['DEMOGRAPHICS_VETERAN'] => demographic_info.veteran, Rails.application.config.x.crm_fields['DEMOGRAPHICS_DISABILITY'] => demographic_info.disability, "addresses"=> [{:label => "mailing", :address_1 => demographic_info.address, :city => demographic_info.city, :state => demographic_info.state, :zipcode => demographic_info.zip, :country => demographic_info.country}]
        })
      demographic_info.save
    end

    it 'saves pronouns to database' do
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
      demographic_info = FactoryBot.build(:demographic_info, :genders=>["Female"], :pronouns=>["they / them / their"], :job=>"test occupation", :salary=>15000, :races=>["Asian or Asian American"], student: student)
      demographic_info.save
      expect(student.reload.pronouns).to eq 'they / them / their'
    end

    it 'sends ssn encrypted' do
      demographic_info = FactoryBot.build(:demographic_info, student: student, ssn: 111111111)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, hash_including(Rails.application.config.x.crm_fields['SSN']))
      expect(CrmUpdateJob).to_not receive(:perform_later).with(lead_id, {'custom.Demographics - Encryped SSN' => '111-11-1111'})
      demographic_info.save
    end
  end
end

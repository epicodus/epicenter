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
  it { should validate_inclusion_of(:education).in_array(DemographicInfo::EDUCATION_OPTIONS) }

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

  it { should validate_length_of(:job).is_at_most(35) }

  # it { should validate_numericality_of(:salary).is_greater_than_or_equal_to(0).with_message("must be greater than or equal to 0") }
  it 'validates salary is greater than or equal to 0' do # test written out due to bug in greater_than_or_equal_to shoulda matcher
    demographic_info = DemographicInfo.new(nil, {salary: -1})
    expect(demographic_info).to_not be_valid
  end

  it 'validates that gender form input is included in list' do
    demographic_info = DemographicInfo.new(nil, {genders: ["not in list"]})
    expect(demographic_info).to_not be_valid
  end

  it 'validates that race form input is included in list' do
    demographic_info = DemographicInfo.new(nil, {races: ["not in list"]})
    expect(demographic_info).to_not be_valid
  end

  it 'validates that shirt size input is included in list' do
    demographic_info = DemographicInfo.new(nil, {shirt: "not in list"})
    expect(demographic_info).to_not be_valid
  end

  describe 'updating close.io with demographics info' do
    let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { close_io_client.list_leads('email:' + student.email)['data'].first['id'] }

    before { allow(CrmUpdateJob).to receive(:perform_later).and_return({}) }

    it 'updates the record successfully', :vcr, :dont_stub_crm do
      demographic_info = FactoryBot.build(:demographic_info, :genders=>["Female"], :job=>"test occupation", :salary=>15000, :races=>["Asian or Asian American"], student: student)
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, {'custom.Demographics - Gender' => demographic_info.genders.join(", "), 'custom.Demographics - Birth date' => demographic_info.birth_date, 'custom.Demographics - Education' => demographic_info.education, 'custom.Demographics - CS Degree' => demographic_info.cs_degree, 'custom.Demographics - Shirt size' => demographic_info.shirt, 'custom.Demographics - Previous job' => demographic_info.job, 'custom.Demographics - Previous salary' => demographic_info.salary, 'custom.Demographics - Race' => demographic_info.races.join(', '), 'custom.Demographics - Veteran' => demographic_info.veteran, 'custom.Demographics - Disability' => demographic_info.disability, "addresses"=> [{:label => "mailing", :address_1 => demographic_info.address, :city => demographic_info.city, :state => demographic_info.state, :zipcode => demographic_info.zip, :country => demographic_info.country}]})
      demographic_info.save
    end
  end
end

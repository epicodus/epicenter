describe DemographicInfo do
  it { should validate_numericality_of(:age).is_greater_than(0).with_message("must be greater than 0") }
  it { should validate_length_of(:job).is_at_most(35) }

  # it { should validate_inclusion_of(:education).in_array(DemographicInfo::EDUCATION_OPTIONS) }
  it 'validates that education input is included in list' do # test written out due to shoulda matcher raising deprecation warning
    demographic_info = DemographicInfo.new(nil, {education: "not in list"})
    expect(demographic_info).to_not be_valid
  end

  # it { should validate_inclusion_of(:veteran).in_array(DemographicInfo::VETERAN_OPTIONS) }
  it 'validates that education input is included in list' do # test written out due to shoulda matcher raising deprecation warning
    demographic_info = DemographicInfo.new(nil, {veteran: "not in list"})
    expect(demographic_info).to_not be_valid
  end

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

  describe 'updating close.io with demographics info' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, email: 'example@example.com') }
    let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }
    let(:lead_id) { close_io_client.list_leads('email:' + student.email).data.first.id }

    before do
      allow(student).to receive(:close_io_client).and_return(close_io_client)
    end

    it 'updates the record successfully', :vcr do
      demographics = {:genders=>["Female"], :age=>50, :education=>"High school diploma or equivalent", :job=>"test occupation", :salary=>15000, :races=>["Asian or Asian American"], :veteran=>"No"}
      demographic_info = DemographicInfo.new(student, demographics)
      expect(close_io_client).to receive(:update_lead).with(lead_id, {'custom.Gender' => demographics[:genders].join(", "), 'custom.Age' => demographics[:age], 'custom.Education' => demographics[:education], 'custom.Previous job' => demographics[:job], 'custom.Previous salary' => demographics[:salary], 'custom.Race' => demographics[:races].join(', '), 'custom.veteran' => demographics[:veteran]})
      demographic_info.save
    end
  end
end

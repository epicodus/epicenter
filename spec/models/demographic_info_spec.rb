describe DemographicInfo do
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

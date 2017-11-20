feature 'Student edits their profile' do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, email: "example@example.com") }
  let(:close_io_client) { Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false) }

  before do
    login_as(student, scope: :student)
    visit edit_student_registration_path
  end

  context 'with the correct password', :dont_stub_crm do
    it "successfully updates information" do
      fill_in 'Name', with: 'New Name'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
    end

    it "successfully updates email", :vcr do
      fill_in 'Email', with: 'second-email@example.com'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
      student.crm_lead.update(email: "example@example.com") # reset for use by other tests
    end

    it "does not update email if new email address is invalid", :vcr do
      fill_in 'Email', with: 'invalid@invalid'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "Invalid email address."
    end
  end

  context 'with the incorrect password' do
    it "shows an error" do
      fill_in 'Name', with: 'New Name'
      fill_in 'Current password', with: 'madeUpPassword'
      click_on 'Update'
      expect(page).to have_content "Current password is invalid"
    end
  end
end

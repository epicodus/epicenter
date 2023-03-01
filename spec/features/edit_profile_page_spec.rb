feature 'Student edits their profile' do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, email: "example@example.com") }

  before do
    login_as(student, scope: :student)
    visit edit_student_registration_path
  end

  context 'with the correct password' do
    it "successfully updates name" do
      fill_in 'Name', with: 'New Name'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
    end

    it "successfully updates pronouns" do
      fill_in 'Pronouns', with: 'test pronouns'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
    end

    it "successfully updates email", :vcr do
      fill_in 'Email', with: 'second-email@example.com'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
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

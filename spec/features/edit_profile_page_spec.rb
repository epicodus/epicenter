feature 'Student edits their profile' do
  context 'with the correct password', :vcr do
    it "successfully updates information" do
      student = FactoryGirl.create(:user_with_credit_card)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      fill_in 'Name', with: 'New Name'
      fill_in 'Current password', with: student.password
      click_on 'Update'
      expect(page).to have_content "You updated your account successfully."
    end
  end

  context 'with the incorrect password', :vcr do
    it "shows an error" do
      student = FactoryGirl.create(:user_with_credit_card)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      fill_in 'Name', with: 'New Name'
      fill_in 'Current password', with: 'madeUpPassword'
      click_on 'Update'
      expect(page).to have_content "Current password is invalid"
    end
  end

end

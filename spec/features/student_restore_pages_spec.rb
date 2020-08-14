feature 'restoring a student' do
  context 'as a student' do
    let(:student) { FactoryBot.create(:user_with_all_documents_signed) }
    let(:archived_student) { FactoryBot.create(:user_with_all_documents_signed) }
    before do
      archived_student.destroy
      login_as(student, scope: :student)
    end

    scenario 'you are not authorized' do
      page.driver.submit :patch, "/students/#{archived_student.id}/restore", {}
      expect(page).to have_content 'not authorized'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:archived_student) { FactoryBot.create(:user_with_all_documents_signed) }
    before do
      FactoryBot.create(:attendance_record, student: archived_student, date: archived_student.course.start_date)
      archived_student.destroy
      login_as(admin, scope: :admin)
    end

    scenario 'you are authorized' do
      page.driver.submit :patch, "/students/#{archived_student.id}/restore?restore=true", {}
      expect(page).to have_content 'Total paid'
    end

    scenario 'you can restore an archived student' do
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: archived_student.name
        click_on 'student-search'
      end
      click_on 'Restore'
      expect(page).to have_content 'Total paid'
      expect(page).to have_content 'restored'
    end

    scenario 'you can permanently delete an archived student' do
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: archived_student.name
        click_on 'student-search'
      end
      allow_any_instance_of(Student).to receive(:really_destroy).and_return({})
      expect_any_instance_of(Student).to receive(:really_destroy)
      click_on "student-expunge-#{archived_student.id}"
      expect(page).to have_content 'expunged'
    end
  end
end

feature 'searching for a student' do
  scenario 'as a guest' do
    visit students_path
    expect(page).to have_content 'You need to sign in.'
  end

  scenario 'as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit students_path
    expect(page).to have_content 'Your courses'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'when no query is made' do
      visit students_path
      click_on 'student-search'
      expect(page).to have_content 'No students found.'
    end

    scenario 'when a query is made for a newly invited student' do
      new_student = FactoryGirl.create(:student)
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: new_student.name
        click_on 'student-search'
      end
      expect(page).to have_content new_student.name
      expect(page).to have_content 'Current student'
    end

    scenario 'when a query is made for an unenrolled student' do
      unenrolled_student = FactoryGirl.create(:student)
      Enrollment.find_by(student: unenrolled_student).destroy
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: unenrolled_student.name
        click_on 'student-search'
      end
      expect(page).to have_content unenrolled_student.name
      expect(page).to have_content 'Not enrolled'
    end

    scenario 'when a query is made for a current student' do
      in_class_student = FactoryGirl.create(:student)
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: in_class_student.name
        click_on 'student-search'
      end
      expect(page).to have_content in_class_student.name
      expect(page).to have_content 'Current student'
    end

    scenario 'when a query is made for a student who has graduated' do
      past_student = FactoryGirl.create(:user_with_all_documents_signed)
      visit root_path
      travel_to past_student.course.end_date + 1.days do
        within '#navbar-search' do
          fill_in 'search', with: past_student.name
          click_on 'student-search'
        end
        expect(page).to have_content past_student.name
        expect(page).to have_content 'Graduate'
      end
    end
  end
end

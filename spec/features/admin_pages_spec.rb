feature 'Admin signs in' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'with valid credentials' do
    visit new_admin_session_path
    fill_in 'Email', with: admin.email
    fill_in 'Password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end

  scenario 'and sees navigation links' do
    login_as(admin, scope: :admin)
    visit root_path
    expect(page).to have_link 'Assessments'
    expect(page).to have_link 'Attendance statistics'
    expect(page).to have_link 'Invite students'
  end
end

feature 'Changing current cohort', js: true do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'admin selects a cohort from the drop down' do
    cohort = FactoryGirl.create(:cohort, description: 'Winter 2015')
    cohort2 = FactoryGirl.create(:cohort, description: 'Spring 2015')
    login_as(admin, scope: :admin)
    visit root_path
    click_link admin.current_cohort.description
    click_link cohort2.description
    expect(page).to have_content "You have switched to #{cohort2.description}"
  end

  context 'when viewing a cohort attendance statistics page' do
    it 'redirects them to the attendance statistics for their current cohort' do
      cohort = FactoryGirl.create(:cohort, description: 'Winter 2015')
      student = FactoryGirl.create(:student, cohort: cohort)
      login_as(admin, scope: :admin)
      visit cohort_attendance_statistics_path(admin.current_cohort)
      expect(page).to have_content student.name
      click_link admin.current_cohort.description
      expect(page).to have_content student.name
    end
  end

  context 'when viewing a cohort assessments page' do
    it 'redirects them to the assessments for their current cohort' do
      cohort = FactoryGirl.create(:cohort, description: 'Winter 2015')
      assessment = FactoryGirl.create(:assessment, cohort: cohort)
      login_as(admin, scope: :admin)
      visit cohort_assessments_path(admin.current_cohort)
      expect(page).to have_content assessment.title
      click_link admin.current_cohort.description
      expect(page).to have_content assessment.title
    end
  end
end

feature 'Inviting new students', js: true do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'admin selects the invite students link' do
    login_as(admin, scope: :admin)
    visit root_path
    click_on 'Invite students'
    expect(page).to have_content "Send invitation"
  end

  scenario 'when submitting an email address of a new student for an invitation email' do
      login_as(admin, scope: :admin)
      visit new_student_invitation_path
      fill_in 'Email', with: 'newstudent@example.com'
      click_on 'Send an invitation'
      expect(page).to have_content "An invitation email has been sent to newstudent@example.com"
  end
end

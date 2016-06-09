feature 'adding an interview assignment' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.create(:internship) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: internship.courses.first) }

  scenario 'as a guest' do
    visit course_student_path(internship.courses.first, student)
    expect(page).to have_content 'You need to sign in'
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit course_student_path(internship.courses.first, student)
    expect(page).to_not have_selector '#interview_assignment_internship_id'
  end

  context 'as an admin' do
    scenario 'successfully' do
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
      select internship.name, from: 'interview_assignment_internship_id'
      click_on 'Add'
      expect(page).to have_content "Interview assignment added for #{student.name}"
    end

    scenario 'unsuccessfully' do
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
      select internship.name, from: 'interview_assignment_internship_id'
      click_on 'Add'
      select internship.name, from: 'interview_assignment_internship_id'
      click_on 'Add'
      expect(page).to have_content 'Please correct these problems'
    end
  end
end

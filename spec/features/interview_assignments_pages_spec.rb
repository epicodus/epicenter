feature 'adding an interview assignment' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.create(:internship) }
  let!(:internship_2) { FactoryGirl.create(:internship, courses: [internship.courses.first]) }
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
    scenario 'adding it successfully' do
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
      select internship.name, from: 'interview_assignment_internship_id'
      select internship_2.name, from: 'interview_assignment_internship_id'
      click_on 'Add'
      expect(page).to have_content "Interview assignments added for #{student.name}"
      within '#interview-assignments-table' do
        expect(page).to have_content internship.name
        expect(page).to have_content internship_2.name
      end
    end
  end
end

feature 'removing an interview assignment' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.create(:internship) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: internship.courses.first) }

  context 'as an admin' do
    scenario 'removing it successfully' do
      FactoryGirl.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
      click_on 'Remove'
      expect(page).to have_content "Interview assignment removed for #{student.name}"
    end
  end
end

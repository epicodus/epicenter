feature 'adding an interview assignment' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:internship) { FactoryBot.create(:internship) }
  let!(:internship_2) { FactoryBot.create(:internship, courses: [internship.courses.first]) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, course: internship.courses.first) }

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
    before do
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
    end

    scenario 'adding it successfully' do
      select internship.name, from: 'interview_assignment_internship_id'
      select internship_2.name, from: 'interview_assignment_internship_id'
      click_on 'Add interviews'
      expect(page).to have_content "Interview assignments added for #{student.name}"
      within '#interview-assignments-table' do
        expect(page).to have_content internship.name
        expect(page).to have_content internship_2.name
      end
    end

    scenario 'adding it unsuccessfully' do
      FactoryBot.create(:interview_assignment, student: student, internship: internship)
      select internship.name, from: 'interview_assignment_internship_id'
      click_on 'Add interviews'
      expect(page).to have_content 'Something went wrong'
    end
  end
end

feature 'removing an interview assignment' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, course: internship.courses.first) }

  context 'as an admin' do
    scenario 'removing it successfully' do
      FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
      login_as(admin, scope: :admin)
      visit course_student_path(internship.courses.first, student)
      click_on 'Remove'
      expect(page).to have_content "Interview assignment removed for #{student.name}"
    end
  end
end

feature 'navigating to the internship page from the interview assignments list' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, course: internship.courses.first) }

  scenario 'as an admin' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    login_as(admin, scope: :admin)
    visit course_student_path(internship.courses.first, student)
    within '#interview-assignments-table' do
      click_on internship.name
    end
    expect(page).to have_content 'Rankings from students'
  end
end

feature 'shows internship details modal from the interview assignments list' do
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, course: internship.courses.first) }

  scenario 'as a student' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    login_as(student, scope: :student)
    visit course_student_path(internship.courses.first, student)
    within '#interview-assignments-table' do
      click_on internship.name
    end
    expect(page).to have_content 'Details'
  end
end

feature 'interview rankings' do
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed, course: internship.courses.first) }
  let(:company) { FactoryBot.create(:company, internships: [internship]) }
  let(:admin) { FactoryBot.create(:admin) }

  scenario 'as a student ranking companies' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    login_as(student, scope: :student)
    visit course_student_path(internship.courses.first, student)
    click_on 'Save rankings'
    expect(page).to have_content 'Interview rankings have been updated.'
  end

  scenario 'as a student ranking companies can add feedback' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    login_as(student, scope: :student)
    visit course_student_path(internship.courses.first, student)
    fill_in 'student-interview-feedback', with: 'Great company!'
    click_on 'Save rankings'
    expect(student.interview_assignments.last.feedback_from_student).to eq 'Great company!'
  end

  scenario 'as a company ranking students' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    login_as(company, scope: :company)
    visit company_path(company)
    fill_in 'company-interview-feedback', with: 'Great interviewer!'
    fill_in 'company-interview-ranking', with: 1
    click_on 'Save rankings'
    expect(page).to have_content "Student rankings have been saved for #{internship.courses.first.description}."
  end

  scenario 'as a company can not view student feedback' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 1, feedback_from_student: 'Great company!')
    login_as(company, scope: :company)
    visit company_path(company)
    expect(page).to_not have_content "Great company!"
  end

  scenario 'as a student can not view company feedback or ranking until 1 week after internship start date' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 5, feedback_from_company: 'Great fit!')
    login_as(student, scope: :student)
    visit course_student_path(internship.courses.first, student)
    expect(page).to have_content "Not yet available."
    expect(page).to_not have_content "5"
  end

  scenario 'as a student can view company feedback and ranking 1 week after internship start date' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 5, feedback_from_company: 'Great fit!')
    login_as(student, scope: :student)
    travel_to student.course.start_date + 1.week do
      visit course_student_path(internship.courses.first, student)
      expect(page).to have_content "Great fit!"
      expect(page).to have_content "5"
    end
  end

  scenario 'as admin can view company feedback immediately' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 1, feedback_from_company: 'Great fit!')
    login_as(admin, scope: :admin)
    visit course_student_path(internship.courses.first, student)
    expect(page).to have_content "Great fit!"
  end

  scenario 'as an admin can view student feedback' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 1, feedback_from_student: 'Great company!')
    login_as(admin, scope: :admin)
    visit course_student_path(internship.courses.first, student)
    expect(page).to have_content "Great company!"
  end
end

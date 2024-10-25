feature 'adding an interview assignment' do
  let(:internship) { FactoryBot.create(:internship) }
  let!(:internship_2) { FactoryBot.create(:internship, courses: [internship.courses.first]) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first) }
  let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

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
      FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
      select internship.name, from: 'interview_assignment_internship_id'
      click_on 'Add interviews'
      expect(page).to have_content 'Something went wrong'
    end
  end
end

feature 'removing an interview assignment' do
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first) }
  let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

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
  let(:internship) { FactoryBot.create(:internship) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first) }
  let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

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
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first) }

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
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first) }
  let(:company) { FactoryBot.create(:company, internships: [internship]) }
  let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

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

  scenario 'as a company ranking students but not all at once' do
    student_2 = FactoryBot.create(:student, :with_all_documents_signed, course: internship.courses.first)
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first)
    FactoryBot.create(:interview_assignment, student: student_2, internship: internship, course: internship.courses.first)
    login_as(company, scope: :company)
    visit company_path(company)
    el1 = page.all(:css, '#company-interview-feedback')[0]
    el2 = page.all(:css, '#company-interview-ranking')[0]
    el1.fill_in with: 'Great interviewer!'
    el2.fill_in with: 1
    click_on 'Save rankings'
    expect(page).to have_content "Student rankings have been saved for #{internship.courses.first.description}."
    expect(Student.first.interview_assignments.first.feedback_from_company).to eq 'Great interviewer!'
    expect(Student.first.interview_assignments.first.ranking_from_company).to eq 1
    expect(Student.last.interview_assignments.first.feedback_from_company).to eq ''
    expect(Student.last.interview_assignments.first.ranking_from_company).to eq nil
    visit company_path(company)
    el3 = page.all(:css, '#company-interview-feedback')[1]
    el4 = page.all(:css, '#company-interview-ranking')[1]
    el3.fill_in with: 'Ok'
    el4.fill_in with: 2
    click_on 'Save rankings'
    expect(page).to have_content "Student rankings have been saved for #{internship.courses.first.description}."
    expect(Student.first.interview_assignments.first.feedback_from_company).to eq 'Great interviewer!'
    expect(Student.first.interview_assignments.first.ranking_from_company).to eq 1
    expect(Student.last.interview_assignments.first.feedback_from_company).to eq 'Ok'
    expect(Student.last.interview_assignments.first.ranking_from_company).to eq 2
  end

  scenario 'as a company can not view student feedback' do
    FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 1, feedback_from_student: 'Great company!')
    login_as(company, scope: :company)
    visit company_path(company)
    expect(page).to_not have_content "Great company!"
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

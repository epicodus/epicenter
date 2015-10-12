feature 'attendance statistics page' do
  let!(:course) { FactoryGirl.create(:course) }

  scenario 'not signed in' do
    visit course_attendance_statistics_path(course)
    expect(page).to have_content 'need to sign in'
  end

  context 'when signed in as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'is navigable through "attendance/statistics"' do
      visit course_attendance_statistics_path(course)
      expect(page).to have_content 'Attendance statistics'
    end

    scenario 'shows number of attendances chart', js: true do
      student = FactoryGirl.create(:student, course: course)
      FactoryGirl.create(:attendance_record, student: student)
      visit course_attendance_statistics_path(course)
      expect(page).to have_content 'Number of students present'
    end

    scenario 'shows chart of breakdown of student attendances', js: true do
      student = FactoryGirl.create(:student, course: course)
      FactoryGirl.create(:attendance_record, student: student)
      visit course_attendance_statistics_path(course)
      expect(page).to have_content student.name
    end
  end

  context 'when signed in as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
    before { login_as(student, scope: :student) }

    scenario 'you are not authorized' do
      visit course_attendance_statistics_path(course)
      expect(page).to have_content 'not authorized'
    end
  end
end

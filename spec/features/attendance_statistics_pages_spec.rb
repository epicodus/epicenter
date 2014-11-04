require 'rails_helper'

feature 'attendance statistics page' do
  let!(:cohort) { FactoryGirl.create(:cohort) }

  scenario 'is navigable through "attendance/statistics"' do
    visit cohort_attendance_statistics_path(cohort)
    expect(page).to have_content 'Attendance statistics'
  end

  scenario 'shows number of attendances chart', js: true do
    student = FactoryGirl.create(:student, cohort: cohort)
    FactoryGirl.create(:attendance_record, student: student)
    visit cohort_attendance_statistics_path(cohort)
    expect(page).to have_content 'Number of students present'
  end

  scenario 'shows chart of breakdown of student attendances', js: true do
    student = FactoryGirl.create(:student, cohort: cohort)
    FactoryGirl.create(:attendance_record, student: student)
    visit cohort_attendance_statistics_path(cohort)
    expect(page).to have_content student.name
  end
end

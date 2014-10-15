require 'rails_helper'

feature 'attendance statistics page' do
  let!(:cohort) { FactoryGirl.create(:cohort) }

  scenario 'is navigable through "attendance/statistics"' do
    visit cohort_attendance_statistics_path(cohort)
    expect(page).to have_content 'Attendance statistics'
  end
end

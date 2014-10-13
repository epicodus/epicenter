require 'rails_helper'

feature 'attendance statistics page' do
  scenario 'is navigable through "attendance/statistics"' do
    visit attendance_statistics_path
    expect(page).to have_content 'Attendance statistics'
  end
end

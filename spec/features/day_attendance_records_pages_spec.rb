feature 'attendance statistics page' do
  let(:course) { FactoryGirl.create(:course) }
  let(:monday) { Time.zone.now.to_date.beginning_of_week }

  scenario 'not signed in' do
    visit course_day_attendance_records_path(course)
    expect(page).to have_content 'need to sign in'
  end

  context 'when signed in as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'can visit day attendance records page' do
      visit course_day_attendance_records_path(course)
      expect(page).to have_content 'Attendance for'
    end

    scenario 'retreiving attendance records for a specific day' do
      travel_to monday do
        visit course_day_attendance_records_path(course)
        click_button 'Change day'
        expect(page).to have_content "Attendance for #{monday.strftime("%A %B %d, %Y")}"
      end
    end
  end
end

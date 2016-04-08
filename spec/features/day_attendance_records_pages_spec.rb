feature 'visiting the day attendance records index page' do
  let(:course) { FactoryGirl.create(:course) }
  let(:monday) { Time.zone.now.to_date.beginning_of_week }

  scenario 'as a guest' do
    visit course_day_attendance_records_path(course)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'can visit the page' do
      visit course_day_attendance_records_path(course)
      expect(page).to have_content 'Attendance for'
    end

    scenario 'can retreive attendance records for a specific day' do
      travel_to monday do
        visit course_day_attendance_records_path(course)
        click_button 'Change day'
        expect(page).to have_content "Attendance for #{monday.strftime("%A %B %d, %Y")}"
      end
    end
  end
end

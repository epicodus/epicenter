feature 'attendance statistics page' do
  let(:cohort) { FactoryGirl.create(:cohort) }
  let(:monday) { Time.zone.now.to_date.beginning_of_week }

  scenario 'not signed in' do
    visit cohort_day_attendance_records_path(cohort)
    expect(page).to have_content 'need to sign in'
  end

  context 'when signed in as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'can visit day attendance records page' do
      visit cohort_day_attendance_records_path(cohort)
      expect(page).to have_content 'Attendance by day'
    end

    scenario 'retreiving attendance records for a specific day' do
      travel_to monday do
        visit cohort_day_attendance_records_path(cohort)
        click_button 'Submit'
        expect(page).to have_content "Attendance for #{monday.strftime("%A %B %d, %Y")}"
      end
    end
  end
end

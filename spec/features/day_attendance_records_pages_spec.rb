feature 'attendance statistics page' do
  let(:cohort) { FactoryGirl.create(:cohort) }

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

    scenario 'retreiving attendance records for a specific day', js: true do
      today = Date.new(2015, 9, 23)
      allow(Date).to receive(:today).and_return(today)
      cohort.start_date = today - 1
      cohort.end_date = today + 1
      visit cohort_day_attendance_records_path(cohort)
      click_button 'Submit'
      expect(page).to have_content "Attendance for #{today.strftime("%A %B %d, %Y")}"
    end
  end
end

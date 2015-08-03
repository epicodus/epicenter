feature "creating an attendance record amendment" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  scenario "when a new record needs to be created" do
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    select student.name, from: "attendance_record_amendment_student_id"
    fill_in "attendance_record_amendment_date", with: student.cohort.start_date.strftime("%F")
    select "On time", from: "attendance_record_amendment_status"
    click_button "Submit"
    expect(page).to have_content "#{student.name}'s attendance record has been amended."
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit new_attendance_record_amendment_path
    expect(page).to have_content "You are not authorized to access this page."
  end

  scenario 'with errors' do
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    click_button "Submit"
    expect(page).to have_content "can't be blank"
  end
end

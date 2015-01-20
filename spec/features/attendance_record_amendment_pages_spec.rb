feature "creating an attendance record amendment" do
  let(:student) { FactoryGirl.create(:student) }

  scenario "when a new record needs to be created" do
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    select student.name, from: "attendance_record_amendment_student_id"
    select "On time", from: "attendance_record_amendment_status"
    # Date should be defaulted to today's date. That is why it is not selected
    # here in the test.
    click_button "Submit"
    expect(page).to have_content "#{student.name}'s attendance record has been amended."
  end
end

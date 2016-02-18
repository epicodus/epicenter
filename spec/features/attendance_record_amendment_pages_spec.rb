feature "creating an attendance record amendment" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  scenario "when a new record needs to be created" do
    admin = FactoryGirl.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    select student.name, from: "attendance_record_amendment_student_id"
    fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
    select "On time", from: "attendance_record_amendment_status"
    click_button "Submit"
    expect(page).to have_content "#{student.name}'s attendance record has been amended."
  end

  scenario "when a new record needs to be created" do
    admin = FactoryGirl.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    select student.name, from: "attendance_record_amendment_student_id"
    fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
    select "Tardy and Left early", from: "attendance_record_amendment_status"
    click_button "Submit"
    expect(page).to have_content "#{student.name}'s attendance record has been amended."
    expect(page).to have_content 'Tardy'
    expect(page).to have_content 'Left early'
    expect(page).to_not have_content 'On time'
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit new_attendance_record_amendment_path
    expect(page).to have_content "You are not authorized to access this page."
  end

  scenario 'with errors' do
    admin = FactoryGirl.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit new_attendance_record_amendment_path
    click_button "Submit"
    expect(page).to have_content "can't be blank"
  end
end

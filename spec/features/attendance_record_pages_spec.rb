feature 'student logging out on attendance page' do
  let!(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  before do
    allow(IpLocation).to receive(:is_local?).and_return(true)
    allow(IpLocation).to receive(:is_local_computer?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(true)
  end

  scenario 'student successfully signs out' do
    FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: student.password
    click_button "Sign out"
    expect(page).to have_content "Goodbye #{student.name}"
  end

  scenario 'student successfully signs out with an uppercased email' do
    FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
    visit sign_out_path
    fill_in "email", with: student.email.upcase
    fill_in "password", with: student.password
    click_button "Sign out"
    expect(page).to have_content "Goodbye #{student.name}"
  end

  scenario 'student fails to log out because they have not logged in yet' do
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: student.password
    click_button "Sign out"
    expect(page).to have_content "You haven't signed in yet today."
  end

  scenario 'student fails to log out because the wrong password is used' do
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: "wrong_password"
    click_button "Sign out"
    expect(page).to have_content 'Invalid email or password.'
  end

  scenario 'student fails to log out because the wrong email is used' do
    visit sign_out_path
    fill_in "email", with: 'wrong_email@epicodus.com'
    fill_in "password", with: student.password
    click_button "Sign out"
    expect(page).to have_content 'Invalid email or password.'
  end
end

feature "admin viewing an individual student's attendance" do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student) }
  let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }
  before { login_as(admin, scope: :admin) }

  scenario "an admin can view attendance records for an individual student" do
    visit course_student_path(student.course, student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario "an admin can navigate through to the attendance record amendment page for a particular record" do
    travel_to student.course.start_date do
      visit course_student_path(student.course, student)
      first('.edit-attendance').click_link 'Edit'
      expect(page).to have_xpath("//input[@value='#{attendance_record.date}']")
    end
  end
end

feature 'viewing attendance records index page' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }
  let(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }

  scenario 'as an admin' do
    login_as(admin, scope: :admin)
    visit student_attendance_records_path(student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit student_attendance_records_path(student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario 'as a guest' do
    visit student_attendance_records_path(student)
    expect(page).to have_content 'You need to sign in'
  end
end

feature 'student logging out on attendance page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:student) { FactoryGirl.create(:user_with_all_documents_signed, email: "student1@example.com") }
  let!(:attendance_record) { FactoryGirl.create(:attendance_record, student: student, date: Time.zone.now.to_date) }

  before { login_as(admin, scope: :admin) }

  scenario 'student successfully logs out' do
    visit sign_out_path
    fill_in "email", with: "student1@example.com"
    fill_in "password", with: "password"
    click_button("Sign Out")
    expect(page).to have_content "Goodbye #{student.name}"
  end
end

feature "admin viewing an individual student's attendance" do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let!(:attendance_record) { FactoryGirl.create(:attendance_record, student: student, date: student.course.start_date + 3) }
  before { login_as(admin, scope: :admin) }

  scenario "an admin can view attendance records for an individual student" do
    travel_to student.course.start_date + 3
    visit student_path(student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario "an admin can navigate through to the attendance record amendment page for a particular record" do
    visit student_path(student)
    within '.student-div.student-attendance' do
      first('li').click_link 'Edit'
    end
    expect(page).to have_xpath("//input[@value='#{attendance_record.date}']")
  end
end

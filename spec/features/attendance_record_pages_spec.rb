feature 'creating an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:student) { FactoryGirl.create(:student, course: admin.current_course, email: "student1@example.com") }
  before { login_as(admin, scope: :admin) }

  scenario 'correctly' do
    visit sign_in_path
    fill_in "email_1", with: "student1@example.com"
    fill_in "password_1", with: "password"
    click_button("Solo")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    FactoryGirl.create(:attendance_record, student: student)
    visit sign_in_path
    fill_in "email_1", with: "student1@example.com"
    fill_in "password_1", with: "password"
    click_button("Solo")
    expect(page).to have_content "Something went wrong:"
  end
end

feature 'destroying an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'after accidentally creating one' do
    FactoryGirl.create(:student, course: admin.current_course, email: "student1@example.com")
    visit sign_in_path
    fill_in "email_1", with: "student1@example.com"
    fill_in "password_1", with: "password"
    click_button("Solo")
    click_link("Not you?")
    expect(page).to have_content 'Attendance record has been deleted'
  end
end

feature 'pair log in for attendance page' do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin, current_course: course) }
  let!(:student_1) { FactoryGirl.create(:user_with_all_documents_signed, course: course, email: "student1@example.com") }
  let!(:student_2) { FactoryGirl.create(:user_with_all_documents_signed, course: course, email: "student2@example.com") }
  before { login_as(admin, scope: :admin) }

  scenario 'students successfully log in as a pair' do
    visit sign_in_path
    fill_in "email_1", with: "student1@example.com"
    fill_in "password_1", with: "password"
    fill_in "email_2", with: "student2@example.com"
    fill_in "password_2", with: "password"
    click_button 'Pair Sign In'
    expect(page).to have_content "Welcome #{student_1.name} and #{student_2.name}."
  end

  scenario 'students try to pair with same student twice' do
    visit sign_in_path
    fill_in "email_1", with: "student1@example.com"
    fill_in "password_1", with: "password"
    fill_in "email_2", with: "student1@example.com"
    fill_in "password_2", with: "password"
    click_button 'Pair Sign In'
    expect(page).to have_content "Something went wrong: Pair cannot be yourself."
  end
end

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

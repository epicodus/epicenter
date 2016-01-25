feature 'student logging out on attendance page' do
  let!(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  before { allow_any_instance_of(Ability).to receive(:is_local).and_return(true) }
  
  scenario 'student successfully logs out' do
    FactoryGirl.create(:attendance_record, student: student, date: Time.zone.now.to_date)
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: student.password
    click_button "Sign Out"
    expect(page).to have_content "Goodbye #{student.name}"
  end

  scenario 'student fails to log out because they have not logged in yet' do
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: student.password
    click_button "Sign Out"
    expect(page).to have_content "You haven't signed in yet today."
  end

  scenario 'student fails to log out because the wrong password is used' do
    visit sign_out_path
    fill_in "email", with: student.email
    fill_in "password", with: "wrong_password"
    click_button "Sign Out"
    expect(page).to have_content 'Invalid email or password.'
  end

  scenario 'student fails to log out because the wrong email is used' do
    visit sign_out_path
    fill_in "email", with: 'wrong_email@epicodus.com'
    fill_in "password", with: student.password
    click_button "Sign Out"
    expect(page).to have_content 'Invalid email or password.'
  end
end

feature "admin viewing an individual student's attendance" do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let!(:attendance_record) { FactoryGirl.create(:attendance_record, student: student, date: student.course.start_date + 3) }
  before do
    login_as(admin, scope: :admin)
    travel_to student.course.start_date + 3
  end

  scenario "an admin can view attendance records for an individual student" do
    visit student_path(student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario "an admin can navigate through to the attendance record amendment page for a particular record" do
    visit student_path(student)
    within '.daily-attendance' do
      first('li').click_link 'Edit'
    end
    expect(page).to have_xpath("//input[@value='#{attendance_record.date}']")
  end
end

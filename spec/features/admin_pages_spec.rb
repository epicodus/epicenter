feature 'Admin signs in' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'with valid credentials' do
    visit new_admin_session_path
    fill_in 'admin_email', with: admin.email
    fill_in 'admin_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end

  scenario 'and sees navigation links' do
    login_as(admin, scope: :admin)
    visit root_path
    expect(page).to have_link 'Code reviews'
    expect(page).to have_link 'Invite'
  end
end

feature 'Changing current course', js: true do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'admin selects a course from the drop down' do
    course = FactoryGirl.create(:course, description: 'Winter 2015')
    course2 = FactoryGirl.create(:course, description: 'Spring 2015')
    login_as(admin, scope: :admin)
    visit root_path
    click_link admin.current_course.description
    click_link course2.description
    expect(page).to have_content "You have switched to #{course2.description}"
  end

  context 'when viewing a course attendance statistics page' do
    it 'redirects them to the attendance statistics for their current course' do
      course = FactoryGirl.create(:course, description: 'Winter 2015')
      student = FactoryGirl.create(:student, course: course)
      login_as(admin, scope: :admin)
      visit course_attendance_statistics_path(admin.current_course)
      expect(page).to have_content student.name
      click_link admin.current_course.description
      expect(page).to have_content student.name
    end
  end

  context 'when viewing a course code review page' do
    it 'redirects them to the code reviews for their current course' do
      course = FactoryGirl.create(:course, description: 'Winter 2015')
      code_review = FactoryGirl.create(:code_review, course: course)
      login_as(admin, scope: :admin)
      visit course_code_reviews_path(admin.current_course)
      expect(page).to have_content code_review.title
      click_link admin.current_course.description
      expect(page).to have_content code_review.title
    end
  end
end

feature 'Inviting new users' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:course) { FactoryGirl.build(:course) }

  before { login_as(admin, scope: :admin) }

  scenario 'admin sends invitation to a student' do
    visit new_student_invitation_path
    select course.description, from: 'student_course_id'
    fill_in 'Email', with: 'newstudent@example.com'
    click_on 'Invite student'
    expect(page).to have_content "An invitation email has been sent to newstudent@example.com to join #{course.description}. Wrong course?"
  end

  scenario 'admin fails to send invitation to a student' do
    visit new_student_invitation_path
    select course.description, from: 'student_course_id'
    fill_in 'Email', with: 'bad_email'
    click_on 'Invite student'
    expect(page).to have_content "Email is invalid"
  end

  scenario 'admin resends invitation to a student' do
    visit new_student_invitation_path
    select course.description, from: 'student_course_id'
    fill_in 'Email', with: 'newstudent@example.com'
    click_on 'Invite student'
    student = Student.find_by(email: 'newstudent@example.com')
    visit course_student_path(student.course, student)
    click_on 'Resend invitation'
    expect(page).to have_content "A new invitation email has been sent to newstudent@example.com"
  end

  scenario 'admin sends invitation to an admin' do
    visit new_admin_invitation_path
    fill_in 'Email', with: 'newadmin@example.com'
    click_on 'Invite admin'
    expect(page).to have_content "An invitation email has been sent to newadmin@example.com"
  end
end

feature 'Admin signs up via invitation' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'with valid information' do
    admin.invite!
    visit accept_admin_invitation_path(admin, invitation_token: admin.raw_invitation_token)
    fill_in 'Name', with: 'Roberta Larson'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Submit'
    expect(page).to have_content 'Your password was set successfully. You are now signed in.'
  end

  scenario 'with missing information' do
    admin.invite!
    visit accept_admin_invitation_path(admin, invitation_token: admin.raw_invitation_token)
    fill_in 'Name', with: ''
    click_on 'Submit'
    expect(page).to have_content 'error'
  end
end

feature 'viewing the student page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let(:unenrolled_student) { FactoryGirl.create(:unenrolled_student) }

  before { login_as(admin, scope: :admin) }

  scenario 'when a student is enrolled in a course' do
    visit course_student_path(student.course, student)
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Code review submissions'
    expect(page).to have_content 'Courses'
  end

  scenario 'when a student is enrolled in a course with internships' do
    FactoryGirl.create(:internship, course: student.course)
    visit course_student_path(student.course, student)
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Code review submissions'
    expect(page).to have_content 'Internships'
    expect(page).to have_content 'Courses'
  end

  scenario 'when a student is not enrolled in any courses' do
    visit course_student_path(unenrolled_student.course, unenrolled_student)
    expect(page).to have_content "#{unenrolled_student.name} is not enrolled in any courses."
  end
end

feature 'student roster page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:course) { FactoryGirl.create(:course) }

  before { login_as(admin, scope: :admin) }

  scenario 'when a teacher visits the sudent roster page when there are no students' do
    visit course_students_path(course)
    expect(page).to have_content 'Student'
    expect(page).to have_content 'Attendance'
  end

  scenario 'when a teacher visits the sudent roster page when there are students' do
    student = FactoryGirl.create(:student, course: course)
    visit course_students_path(course)
    expect(page).to have_content student.name
  end
end

feature 'Admin signs in' do
  let(:admin) { FactoryGirl.create(:admin) }

  after { OmniAuth.config.mock_auth[:github] = nil }

  scenario 'with valid credentials' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end

  scenario 'with an uppercase email' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email.upcase
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end

  scenario 'with valid GitHub credentials the first time' do
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: admin.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with valid GitHub credentials on subsequent logins' do
    admin = FactoryGirl.create(:admin, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: admin.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with a valid GitHub email but invalid uid on subsequent logins' do
    admin = FactoryGirl.create(:admin, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '98765', info: { email: admin.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Your GitHub and Epicenter credentials do not match.'
  end

  scenario 'with mismatching GitHub and Epicenter emails' do
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: 'wrong_email@example.com' }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Your GitHub and Epicenter credentials do not match.'
  end

  scenario 'and sees navigation links' do
    login_as(admin, scope: :admin)
    visit root_path
    expect(page).to have_link 'Invite'
  end
end

feature 'Changing current course' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'admin selects a new course' do
    course2 = FactoryGirl.create(:course, description: 'Spring 2015')
    login_as(admin, scope: :admin)
    visit root_path
    click_link 'Courses'
    click_link course2.description
    expect(page).to have_content "You have switched to #{course2.description}"
  end
end

feature 'Inviting new users', :vcr do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:course) { FactoryGirl.create(:course, description: '* Placement Test') }

  before { login_as(admin, scope: :admin) }

  scenario 'admin sends invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    expect(page).to have_content "An invitation email has been sent to example@example.com to join #{course.description}. Wrong course?"
  end

  scenario 'admin fails to send invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'bad_email'
    click_on 'Invite student'
    expect(page).to have_content "Invalid email / name / course"
  end

  scenario 'admin resends invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    student = Student.find_by(email: 'example@example.com')
    visit student_courses_path(student)
    click_on 'Resend invitation'
    expect(page).to have_content "A new invitation email has been sent to example@example.com"
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
    expect(page).to have_content 'Code reviews'
  end

  scenario 'when a student is enrolled in a course with internships' do
    FactoryGirl.create(:internship, courses: [student.course])
    visit course_student_path(student.course, student)
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Code reviews'
    expect(page).to have_content 'Internships'
  end

  scenario 'when a student is not enrolled in any courses' do
    visit student_courses_path(unenrolled_student)
    expect(page).to have_content 'Not enrolled'
  end
end

feature 'student roster page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:course) { FactoryGirl.create(:course) }

  before { login_as(admin, scope: :admin) }

  scenario 'when a teacher visits the sudent roster page when there are no students' do
    visit course_path(course)
    expect(page).to have_content 'Student'
    expect(page).to have_content 'Attendance'
  end

  scenario 'when a teacher visits the sudent roster page when there are students' do
    student = FactoryGirl.create(:student, course: course)
    visit course_path(course)
    expect(page).to have_content student.name
  end
end

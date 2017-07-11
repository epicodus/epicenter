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

feature 'Changing current course for teacher' do
  let(:teacher) { FactoryGirl.create(:teacher) }
  let(:course) { FactoryGirl.create(:course) }

  scenario 'admin selects a new course' do
    course2 = FactoryGirl.create(:internship_course)
    login_as(teacher, scope: :admin)
    visit root_path
    click_link 'Courses'
    click_link course2.description
    expect(page).to have_content "You have switched to #{course2.description}"
  end
end

feature 'Does not change current course for non-teacher admin' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:course) { FactoryGirl.create(:course) }

  scenario 'non-teacher admin views a course' do
    course2 = FactoryGirl.create(:internship_course)
    login_as(admin, scope: :admin)
    visit root_path
    click_link 'Courses'
    click_link course2.description
    expect(page).to_not have_content "You have switched to #{course2.description}"
  end
end

feature 'Inviting new full-time students', :vcr do
  let(:cohort) { FactoryGirl.create(:cohort, start_date: Date.parse('2000-01-03')) }

  before do
    admin = cohort.admin
    admin.current_course = cohort.courses.first
    login_as(admin, scope: :admin)
  end

  scenario 'admin invites full-time student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    expect(page).to have_content "An invitation email has been sent to example@example.com to join #{cohort.courses.first.description} in #{cohort.office.name}. Wrong course?"
  end

  scenario 'starting cohort automatically set when admin sends invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    student = Student.find_by(email: "example@example.com")
    expect(student.starting_cohort_id).to eq cohort.courses.first.id
  end
end

feature 'Inviting new part-time students', :vcr do
  let(:course) { FactoryGirl.create(:part_time_course, description: '* Placement Test', class_days: [Date.parse('2000-01-03')]) }
  let(:admin) { FactoryGirl.create(:admin, courses: [course]) }

  before do
    login_as(admin, scope: :admin)
    admin.current_course = course
  end

  scenario 'admin invites part-time student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example-part-time@example.com'
    click_on 'Invite student'
    expect(page).to have_content "An invitation email has been sent to example-part-time@example.com to join #{admin.current_course.description} in #{admin.current_course.office.name}. Wrong course?"
  end

  scenario 'does not set starting cohort' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example-part-time@example.com'
    click_on 'Invite student'
    student = Student.find_by(email: "example-part-time@example.com")
    expect(student.starting_cohort_id).to eq nil
  end

  scenario 'admin fails to send invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'bad_email'
    click_on 'Invite student'
    expect(page).to have_content "Email not found"
  end

  scenario 'admin resends invitation to a student' do
    visit new_student_invitation_path
    fill_in 'Email', with: 'example-part-time@example.com'
    click_on 'Invite student'
    student = Student.find_by(email: 'example-part-time@example.com')
    visit student_courses_path(student)
    click_on 'Resend invitation'
    expect(page).to have_content "A new invitation email has been sent to example-part-time@example.com"
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
  let(:internship_student) { FactoryGirl.create(:student, courses: [FactoryGirl.create(:internship_course)]) }

  before do
    allow_any_instance_of(Student).to receive(:update_close_io)
    login_as(admin, scope: :admin)
  end

  scenario 'when a student is enrolled in a course' do
    visit course_student_path(student.course, student)
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Code reviews'
    expect(page).to have_content student.course.description
    expect(page).to_not have_content 'withdrawn'
    expect(page).to_not have_content 'not enrolled'
  end

  scenario 'when a student is enrolled in a course with internships' do
    FactoryGirl.create(:internship, courses: [internship_student.course])
    visit course_student_path(internship_student.course, internship_student)
    expect(page).to have_content 'Code reviews'
    expect(page).to have_content 'Internships'
  end

  scenario 'when a student is not enrolled in any courses' do
    visit student_courses_path(unenrolled_student)
    expect(page).to have_content 'Not enrolled'
  end

  scenario 'when a student has withdrawn from a course' do
    FactoryGirl.create(:attendance_record, student: student, date: student.course.start_date)
    Enrollment.find_by(student: student, course: student.course).destroy
    visit course_student_path(student.course, student)
    expect(page).to have_content 'withdrawn'
  end

  scenario 'when a student was never enrolled in a course' do
    other_course = FactoryGirl.create(:past_course)
    visit course_student_path(other_course, student)
    expect(page).to have_content 'not enrolled'
  end
end

feature 'viewing the student courses list' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:course1) { FactoryGirl.create(:course) }
  let(:course2) { FactoryGirl.create(:internship_course) }
  let(:student) { FactoryGirl.create(:student, courses: [course1, course2]) }

  before do
    FactoryGirl.create(:attendance_record, student: student, date: course1.start_date)
    login_as(admin, scope: :admin)
  end

  it 'shows enrolled course' do
    visit student_courses_path(student)
    expect(page).to have_content student.course.description
    expect(page).to_not have_content 'Withdrawn'
  end

  it 'shows withdrawn course in separate section' do
    Enrollment.find_by(student: student, course: course1).destroy
    visit student_courses_path(student)
    expect(page).to have_content course2.description
    expect(page).to have_content 'Withdrawn:'
    expect(page).to have_content "#{course1.description} (1 sign-ins, withdrawn"
  end

  it 'allows admin to click through to view code reviews for withdrawn course' do
    Enrollment.find_by(student: student, course: course1).destroy
    visit student_courses_path(student)
    within '.well' do
      click_link course1.description
    end
    expect(page).to have_content "#{course1.description} (withdrawn)"
    expect(page).to have_content 'Code reviews'
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

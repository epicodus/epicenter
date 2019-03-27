feature 'Admin signs in' do
  let(:admin) { FactoryBot.create(:admin) }

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
    admin = FactoryBot.create(:admin, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: admin.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with a valid GitHub email but invalid uid on subsequent logins' do
    admin = FactoryBot.create(:admin, github_uid: '12345')
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
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:course) { FactoryBot.create(:course) }

  scenario 'admin selects a new course' do
    course2 = FactoryBot.create(:internship_course)
    login_as(teacher, scope: :admin)
    visit root_path
    click_link 'Courses'
    all('a', text: course2.description).last.click
    expect(page).to have_content "You have switched to #{course2.description}"
  end
end

feature 'Does not change current course for non-teacher admin' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:course) { FactoryBot.create(:course) }

  scenario 'non-teacher admin views a course' do
    course2 = FactoryBot.create(:internship_course)
    login_as(admin, scope: :admin)
    visit root_path
    click_link 'Courses'
    click_link course2.description
    expect(page).to_not have_content "You have switched to #{course2.description}"
  end
end

feature 'Inviting new students', :vcr, :stub_mailgun, :dont_stub_crm do
  let(:cohort) { FactoryBot.create(:intro_only_cohort, start_date: Date.parse('2000-01-03')) }

  before do
    admin = cohort.admin
    admin.current_course = cohort.courses.first
    login_as(admin, scope: :admin)
  end

  scenario 'admin invites student' do
    allow_any_instance_of(Closeio::Client).to receive(:subscribe).and_return({})
    allow_any_instance_of(Closeio::Client).to receive(:create_task).and_return({})
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    expect(page).to have_content "example@example.com has been invited to Epicenter"
  end

  scenario 'does not allow inviting if email already taken' do
    FactoryBot.create(:student, email: 'example@example.com')
    visit new_student_invitation_path
    fill_in 'Email', with: 'example@example.com'
    click_on 'Invite student'
    expect(page).to have_content "Email already used in Epicenter"
  end

  scenario 'admin resends invitation to a student' do
    student = Student.invite!(email: 'example@example.com')
    visit student_courses_path(student)
    click_on 'Resend invitation'
    expect(page).to have_content "A new invitation email has been sent to example@example.com"
  end
end

feature 'Admin signs up via invitation' do
  let(:admin) { FactoryBot.create(:admin) }

  scenario 'with valid information' do
    admin.invite!
    visit accept_admin_invitation_path(admin, invitation_token: admin.raw_invitation_token)
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Submit'
    expect(page).to have_content 'Your password was set successfully. You are now signed in.'
  end

  scenario 'with missing information' do
    admin.invite!
    visit accept_admin_invitation_path(admin, invitation_token: admin.raw_invitation_token)
    fill_in 'Password', with: ''
    click_on 'Submit'
    expect(page).to have_content 'error'
  end
end

feature 'viewing the student page' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:course) { FactoryBot.create(:midway_course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:unenrolled_student) { FactoryBot.create(:unenrolled_student) }
  let(:internship_student) { FactoryBot.create(:student, courses: [FactoryBot.create(:internship_course)]) }

  before { login_as(admin, scope: :admin) }

  scenario 'when a student is enrolled in a course' do
    visit course_student_path(student.course, student)
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Code reviews'
    expect(page).to have_content student.course.description
    expect(page).to_not have_content 'withdrawn'
    expect(page).to_not have_content 'not enrolled'
  end

  scenario 'when a student is enrolled in a course with internships' do
    FactoryBot.create(:internship, courses: [internship_student.course])
    visit course_student_path(internship_student.course, internship_student)
    expect(page).to have_content 'Code reviews'
    expect(page).to have_content 'Internships'
  end

  scenario 'when a student is not enrolled in any courses' do
    visit student_courses_path(unenrolled_student)
    expect(page).to have_content 'Not enrolled'
  end

  scenario 'when a student has withdrawn from a course' do
    FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
    Enrollment.find_by(student: student, course: student.course).destroy
    visit course_student_path(student.course, student)
    expect(page).to have_content 'withdrawn'
  end

  scenario 'when a student was never enrolled in a course' do
    other_course = FactoryBot.create(:past_course)
    visit course_student_path(other_course, student)
    expect(page).to have_content 'not enrolled'
  end
end

feature 'viewing the student courses list' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:course1) { FactoryBot.create(:midway_course) }
  let(:course2) { FactoryBot.create(:internship_course) }
  let(:student) { FactoryBot.create(:student, courses: [course1, course2]) }

  before do
    FactoryBot.create(:attendance_record, student: student, date: course1.start_date)
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
    within '#withdrawn-courses' do
      click_link course1.description
    end
    expect(page).to have_content "#{course1.description} (withdrawn)"
    expect(page).to have_content 'Code reviews'
  end
end

feature 'student roster page' do
  let(:admin) { FactoryBot.create(:admin) }
  let!(:course) { FactoryBot.create(:course) }

  before { login_as(admin, scope: :admin) }

  scenario 'when a teacher visits the sudent roster page when there are no students' do
    visit course_path(course)
    expect(page).to have_content 'Student'
    expect(page).to have_content 'Attendance'
  end

  scenario 'when a teacher visits the sudent roster page when there are students' do
    student = FactoryBot.create(:student, course: course)
    visit course_path(course)
    expect(page).to have_content student.name
  end

  scenario 'allows viewing attendance' do
    student = FactoryBot.create(:student, course: course)
    visit course_path(course)
    click_link 'View attendance'
    expect(page).to have_content '0%'
  end

  scenario 'allows viewing payment plans' do
    student = FactoryBot.create(:student, course: course)
    visit course_path(course)
    click_link 'View payment plans'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and payment plans' do
    student = FactoryBot.create(:student, course: course)
    visit course_path(course)
    click_link 'View attendance'
    click_link 'View payment plans'
    expect(page).to have_content '0%'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and payment plans (other order)' do
    student = FactoryBot.create(:student, course: course)
    visit course_path(course)
    click_link 'View payment plans'
    click_link 'View attendance'
    expect(page).to have_content '0%'
    expect(page).to have_content student.plan.name
  end
end

feature 'exporting course students emails to a file' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }
    scenario 'exports email addresses for students in a course' do
      visit course_path(student.course)
      click_link 'export-btn'
      filename = Rails.root.join('tmp','students.txt')
      expect(filename).to exist
    end
  end

  context 'as a student' do
    before { login_as(student, scope: :student) }
    scenario 'without permission' do
      visit course_export_path(student.course)
      expect(page).to have_content "You are not authorized to access this page."
    end
  end
end

feature 'archiving student' do
  let(:admin) { FactoryBot.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'archiving a student with courses' do
    student = FactoryBot.create(:student)
    visit student_courses_path(student)
    click_on 'Drop All'
    click_on 'Archive student'
    expect(page).to have_content "#{student.name} has been archived!"
  end

  scenario 'archiving a student without courses' do
    student = FactoryBot.create(:student_without_courses)
    visit student_courses_path(student)
    click_on 'Archive student'
    expect(page).to have_content "#{student.name} has been archived!"
  end
end

feature 'receiving callback to archive student', :js do
  context 'with valid token' do
    it "initiates WithdrawCallback" do
      fake_webhook = FakeWebhook.new( fixture: "zapier_withdraw_webhook.json", path: "/withdraw_callbacks", host: Capybara.current_session.server.host, port: Capybara.current_session.server.port, token: ENV['ZAPIER_SECRET_TOKEN'] )
      expect(WithdrawCallback).to receive(:new)
      fake_webhook.send
    end
  end

  context 'with invalid token' do
    it "returns 404" do
      fake_webhook = FakeWebhook.new( fixture: "zapier_withdraw_webhook.json", path: "/withdraw_callbacks", host: Capybara.current_session.server.host, port: Capybara.current_session.server.port )
      expect(WithdrawCallback).to_not receive(:new)
      expect { fake_webhook.send }.to raise_error(RestClient::NotFound)
    end
  end
end

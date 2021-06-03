feature 'Admin signs in' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }

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
    admin.github_uid = '12345'
    admin.save
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

feature 'Inviting new students', :vcr, :stub_mailgun, :dont_stub_crm do
  let(:cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Date.parse('2000-01-03')) }

  before do
    admin = cohort.admin
    admin.current_course = cohort.courses.first
    login_as(admin, scope: :admin)
  end

  scenario 'admin invites student' do
    allow_any_instance_of(Closeio::Client).to receive(:create_task).and_return({})
    allow_any_instance_of(CrmLead).to receive(:cohort_applied).and_return(cohort.description)
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
  let(:admin) { FactoryBot.create(:admin, :with_course) }

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
  let(:course) { FactoryBot.create(:midway_course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:admin) { course.admin }
  let(:unenrolled_student) { FactoryBot.create(:student) }
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
    FactoryBot.create(:internship, courses: [internship_student.courses.internship_courses.first])
    visit course_student_path(internship_student.course, internship_student)
    expect(page).to have_content 'Career reviews'
    expect(page).to have_content 'Internships'
  end

  scenario 'when a student is not enrolled in any courses' do
    visit student_courses_path(unenrolled_student)
    expect(page).to have_content 'Not enrolled'
  end

  scenario 'when a student has withdrawn from a course' do
    FactoryBot.create(:attendance_record, student: student, date: student.course.start_date + 1.week)
    Enrollment.find_by(student: student, course: student.course).destroy
    visit course_student_path(student.course, student)
    expect(page).to have_content 'withdrawn'
  end

  scenario 'when a student was never enrolled in a course' do
    other_course = FactoryBot.create(:past_course)
    visit course_student_path(other_course, student)
    expect(page).to have_content 'not enrolled'
  end

  scenario 'navigating to view course from student page' do
    visit course_student_path(student.course, student)
    click_link 'view'
    expect(current_path).to eq course_path(course)
  end
end

feature 'viewing the student courses list' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:course1) { FactoryBot.create(:midway_course, admin: admin) }
  let(:course2) { FactoryBot.create(:internship_course, admin: admin) }
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

feature 'manually changing current cohort' do
  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:ft_cohort) { FactoryBot.create(:ft_cohort, admin: admin) }
    let(:ft_cohort_2) { FactoryBot.create(:ft_cohort, admin: admin) }
    let(:pt_intro_cohort) { FactoryBot.create(:pt_intro_cohort, admin: admin) }

    before { login_as(admin, scope: :admin) }

    it 'does not show link to change current cohort when only one possible cirr cohort' do
      student = FactoryBot.create(:student, courses: ft_cohort.courses + pt_intro_cohort.courses)
      visit student_courses_path(student)
      expect(page).to_not have_content 'edit current cohort'
    end

    it 'shows link to change current cohort when multiple possible cirr cohorts' do
      student = FactoryBot.create(:student, courses: ft_cohort.courses + ft_cohort_2.courses)
      visit student_courses_path(student)
      expect(page).to have_content 'edit current cohort'
    end

    it 'shows modal to change current cohort when click edit current cohort link', :js do
      student = FactoryBot.create(:student, courses: ft_cohort.courses + ft_cohort_2.courses)
      visit student_courses_path(student)
      click_on 'edit current cohort'
      expect(page).to have_content "Confirm updated current cohort for #{student.name}"
    end
  end

  context 'as a student' do
    it 'does not show link to change current cohort' do
      ft_cohort = FactoryBot.create(:ft_cohort)
      ft_cohort_2 = FactoryBot.create(:ft_cohort)
      student = FactoryBot.create(:student, courses: ft_cohort.courses + ft_cohort_2.courses)
      login_as(student, scope: :student)
      visit student_courses_path(student)
      expect(page).to_not have_content 'edit current cohort'
    end
  end
end

feature 'setting academic probation', :js, :stub_mailgun do
  let(:student) { FactoryBot.create(:student, :with_course) }
  let(:admin) { student.course.admin }

  before do
    login_as(admin, scope: :admin)
  end

  it 'sets teacher academic probation' do
    visit student_courses_path(student)
    find(:css, "#student_probation_teacher").set(true)
    accept_js_alert
    expect(page).to have_content "#{student.name} has been placed on teacher warning!"
    student.reload
    expect(student.probation_teacher).to eq true
  end

  it 'sets advisor academic probation' do
    visit student_courses_path(student)
    find(:css, "#student_probation_advisor").set(true)
    accept_js_alert
    expect(page).to have_content "#{student.name} has been placed on advisor warning!"
    student.reload
    expect(student.probation_advisor).to eq true
  end

  it 'unsets teacher academic probation' do
    student.update_columns(probation_teacher: true)
    visit student_courses_path(student)
    find(:css, "#student_probation_teacher").set(false)
    accept_js_alert
    expect(page).to have_content "#{student.name} has been removed from teacher warning! :)"
    student.reload
    expect(student.probation_teacher).to eq false
  end

  it 'unsets advisor academic probation' do
    student.update_columns(probation_advisor: true)
    visit student_courses_path(student)
    find(:css, "#student_probation_advisor").set(false)
    accept_js_alert
    expect(page).to have_content "#{student.name} has been removed from advisor warning! :)"
    student.reload
    expect(student.probation_advisor).to eq false
  end

  it 'shows number of times student has been on teacher probation' do
    visit student_courses_path(student)
    expect(page).to have_content 'Teacher warnings: (0 times)'
    student.update_columns(probation_teacher_count: 1)
    visit student_courses_path(student)
    expect(page).to have_content 'Teacher warnings: (1 time)'
  end

  it 'shows number of times student has been on advisor probation' do
    visit student_courses_path(student)
    expect(page).to have_content 'Advisor warnings: (0 times)'
    student.update_columns(probation_advisor_count: 1)
    visit student_courses_path(student)
    expect(page).to have_content 'Advisor warnings: (1 time)'
  end

  it 'allows editing of probation counts' do
    visit student_courses_path(student)
    expect(page).to have_content 'Teacher warnings: (0 times)'
    expect(page).to have_content 'Advisor warnings: (0 times)'
    click_link 'edit count'
    fill_in 'probation-teacher-count-input', with: '1'
    fill_in 'probation-advisor-count-input', with: '1'
    click_button 'Update'
    expect(page).to have_content 'Teacher warnings: (1 time)'
    expect(page).to have_content 'Advisor warnings: (1 time)'
  end
end

feature 'student roster page' do
  let!(:course) { FactoryBot.create(:course) }
  let(:admin) { course.admin }

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
    expect(page).to have_content '0'
    expect(page).to have_content 'Attendance'
    expect(page).to have_content 'Course absences'
    expect(page).to have_content 'Cohort absences'
  end

  scenario 'allows viewing probation count' do
    student = FactoryBot.create(:student, course: course, probation_advisor_count: nil, probation_teacher_count: 123)
    visit course_path(course)
    click_link 'View academic warnings'
    expect(page).to have_content 123
  end

  scenario 'allows viewing payment plans' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    visit course_path(course)
    click_link 'View payment plans'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing feedback of student' do
    student = FactoryBot.create(:student, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View feedback'
    expect(page).to have_content 6
  end

  scenario 'allows viewing both attendance and payment plans' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    visit course_path(course)
    click_link 'View attendance'
    click_link 'View payment plans'
    expect(page).to have_content '0%'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and payment plans (other order)' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    visit course_path(course)
    click_link 'View payment plans'
    click_link 'View attendance'
    expect(page).to have_content '0%'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and feedback' do
    student = FactoryBot.create(:student, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View attendance'
    click_link 'View feedback'
    expect(page).to have_content '0%'
    expect(page).to have_content 6
  end

  scenario 'allows viewing both attendance and feedback (other order)' do
    student = FactoryBot.create(:student, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View feedback'
    click_link 'View attendance'
    expect(page).to have_content '0%'
    expect(page).to have_content 6
  end

  scenario 'allows viewing both feedback and payment plans' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View feedback'
    click_link 'View payment plans'
    expect(page).to have_content 6
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both feedback and payment plans (other order)' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View payment plans'
    click_link 'View feedback'
    expect(page).to have_content 6
    expect(page).to have_content student.plan.name
  end
end

feature 'exporting course students emails to a file' do
  let(:student) { FactoryBot.create(:student, :with_course) }
  let(:admin) { student.course.admin }

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
  scenario 'archiving a student with courses' do
    student = FactoryBot.create(:student, :with_course)
    admin = student.course.admin
    login_as(admin, scope: :admin)
    visit student_courses_path(student)
    click_on 'Drop All'
    click_on 'Archive student'
    expect(page).to have_content "#{student.name} has been archived!"
  end

  scenario 'archiving a student without courses' do
    other_course = FactoryBot.create(:course)
    admin = other_course.admin
    student = FactoryBot.create(:student, courses: [])
    login_as(admin, scope: :admin)
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

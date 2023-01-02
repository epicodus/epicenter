feature 'Admin signs in' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:admin_with_2fa) { FactoryBot.create(:admin, :with_course, :with_2fa) }

  after { OmniAuth.config.mock_auth[:github] = nil }

  scenario 'with valid credentials' do
    visit root_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end

  scenario 'with an uppercase email' do
    visit root_path
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
    expect(page).to have_link 'Cohorts'
  end

  scenario 'student sign-in page redirects to root sign-in page' do
    visit new_student_session_path
    expect(page).to have_current_path root_path
  end

  scenario 'company sign-in page redirects to root sign-in page' do
    visit new_company_session_path
    expect(page).to have_current_path root_path
  end

  scenario 'admin sign-in page redirects to root sign-in page' do
    visit new_admin_session_path
    expect(page).to have_current_path root_path
  end

  scenario 'Successfully from users sign-in page' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in successfully'
  end

  scenario 'Successfully from root sign-in page' do
    visit root_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in successfully'
  end

  scenario 'unsuccessfully from root sign-in page when 2fa required but not entered' do
    visit root_path
    fill_in 'user_email', with: admin_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to_not have_content 'Signed in successfully'
    click_on 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  scenario 'unsuccessfully from root sign-in page when incorrect 2fa code' do
    visit root_path
    fill_in 'user_email', with: admin_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to_not have_content 'Signed in successfully'
    fill_in 'user_otp_attempt', with: 'wrong'
    click_on 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  scenario 'successfully from root sign-in page when 2fa code' do
    visit root_path
    fill_in 'user_email', with: admin_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    fill_in 'user_otp_attempt', with: admin_with_2fa.current_otp
    click_on 'Sign in'
    expect(page).to have_content 'Signed in successfully'
  end
end

feature 'Inviting new students', :vcr, :stub_mailgun, :dont_stub_crm do
  let(:cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Date.parse('2000-01-03')) }

  before do
    admin = cohort.admin
    admin.current_course = cohort.courses.first
    login_as(admin, scope: :admin)
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

  context 'when a student is enrolled in a course with code reviews' do
    scenario 'on course page' do
      code_review = FactoryBot.create(:code_review, course: student.course)
      visit course_path(student.course)
      section = find(:css, '#code-reviews-box')
      expect(section).to have_content code_review.title
      expect(section).to have_content 'Number'
      expect(section).to have_content 'Visible'
      expect(section).to have_content 'Due'
      expect(section).to have_content 'Title'
      expect(section).to have_content 'Report'
      expect(section).to have_content 'Submissions'
    end

    scenario 'on course student page' do
      code_review = FactoryBot.create(:code_review, course: student.course)
      visit course_student_path(student.course, student)
      section = find(:css, '#code-reviews-box')
      expect(section).to have_content code_review.title
      expect(section).to have_content 'Title'
      expect(section).to have_content 'Expectations met?'
      expect(section).to have_content 'Times submitted'
      expect(section).to have_content 'Submission link'
      expect(section).to have_content 'Status'
      expect(section).to_not have_content 'Complete?'
    end
  end

  context 'when a student is enrolled in a course with reflections' do
    scenario 'on course page' do
      journal = FactoryBot.create(:code_review, course: student.course, journal: true)
      visit course_path(student.course)
      section = find(:css, '#journal-entries-box')
      expect(section).to have_content journal.title
      expect(section).to have_content 'Number'
      expect(section).to have_content 'Visible'
      expect(section).to have_content 'Due'
      expect(section).to have_content 'Title'
      expect(section).to have_content 'Report'
      expect(section).to have_content 'Submissions'
    end

    scenario 'on course student page' do
      journal = FactoryBot.create(:code_review, course: student.course, journal: true)
      visit course_student_path(student.course, student)
      section = find(:css, '#journal-entries-box')
      expect(section).to have_content journal.title
      expect(section).to have_content 'Title'
      expect(section).to have_content 'Complete?'
      expect(section).to have_content 'Status'
      expect(section).to_not have_content 'Expectations met?'
      expect(section).to_not have_content 'Times submitted'
      expect(section).to_not have_content 'Submission link'
    end
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

    before do
      ft_cohort_2.update(description: 'ft cohort 2')
      login_as(admin, scope: :admin)
    end

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

    it 'allow changing current cohort', :js do
      student = FactoryBot.create(:student, courses: ft_cohort.courses + ft_cohort_2.courses)
      visit student_courses_path(student)
      click_on 'edit current cohort'
      select ft_cohort_2.reload.description, from: 'current_cohort_id'
      click_on 'Confirm current cohort'
      expect(student.reload.cohort).to eq ft_cohort_2
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

feature 'manually changing starting cohort' do
  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let!(:ft_cohort) { FactoryBot.create(:ft_cohort, admin: admin) }
    let(:ft_cohort_2) { FactoryBot.create(:ft_cohort, admin: admin) }
    let(:pt_intro_cohort) { FactoryBot.create(:pt_intro_cohort, admin: admin) }

    before { login_as(admin, scope: :admin) }

    it 'shows link to change starting cohort regardeless of enrollment' do
      student = FactoryBot.create(:student)
      visit student_courses_path(student)
      expect(page).to have_content 'edit starting cohort'
    end

    it 'shows modal to change starting cohort when click edit starting cohort link', :js do
      student = FactoryBot.create(:student)
      visit student_courses_path(student)
      click_on 'edit starting cohort'
      expect(page).to have_content "Confirm updated starting cohort for #{student.name}"
    end

    it 'allow changing starting cohort', :js do
      student = FactoryBot.create(:student)
      visit student_courses_path(student)
      click_on 'edit starting cohort'
      select ft_cohort.description, from: 'starting_cohort_id'
      click_on 'Confirm starting cohort'
      expect(student.reload.starting_cohort).to eq ft_cohort
    end
  end

  context 'as a student' do
    it 'does not show link to change starting cohort' do
      student = FactoryBot.create(:student)
      login_as(student, scope: :student)
      visit student_courses_path(student)
      expect(page).to_not have_content 'edit starting cohort'
    end
  end
end

feature 'setting academic probation', :js, :stub_mailgun, :vcr do
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

  describe 'notification' do
    before do
      allow(WebhookEmail).to receive(:new).and_return({})
      allow_any_instance_of(CrmLead).to receive(:create_task).and_return({})
    end

    it 'is sent to advisor and teacher when teacher probation enabled' do
      visit student_courses_path(student)
      find(:css, "#student_probation_teacher").set(true)
      expect_any_instance_of(CrmLead).to receive(:create_task).with("Student placed on teacher probation by #{admin.name}")
      expect(WebhookEmail).to receive(:new)
      accept_js_alert
    end

    it 'is sent to advisor only when teacher probation disabled' do
      student.update_columns(probation_teacher: true)
      visit student_courses_path(student)
      find(:css, "#student_probation_teacher").set(false)
      expect_any_instance_of(CrmLead).to receive(:create_task).with("Student removed from teacher probation by #{admin.name}")
      expect(WebhookEmail).to_not receive(:new)
      accept_js_alert
    end

    it 'is not sent when advisor probation enabled' do
      visit student_courses_path(student)
      find(:css, "#student_probation_advisor").set(true)
      expect_any_instance_of(CrmLead).to_not receive(:create_task)
      expect(WebhookEmail).to_not receive(:new)
      accept_js_alert
    end
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
    expect(page).to have_content 'Program absences'
    expect(page).to have_content '0'
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
    expect(page).to have_content 'Program absences'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and payment plans (other order)' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    visit course_path(course)
    click_link 'View payment plans'
    click_link 'View attendance'
    expect(page).to have_content 'Program absences'
    expect(page).to have_content student.plan.name
  end

  scenario 'allows viewing both attendance and feedback' do
    student = FactoryBot.create(:student, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View attendance'
    click_link 'View feedback'
    expect(page).to have_content 'Program absences'
    expect(page).to have_content 6
  end

  scenario 'allows viewing both attendance and feedback (other order)' do
    student = FactoryBot.create(:student, course: course)
    FactoryBot.create(:pair_feedback, pair: student)
    visit course_path(course)
    click_link 'View feedback'
    click_link 'View attendance'
    expect(page).to have_content 'Program absences'
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

  scenario 'shows icon when student has requested a meeting for this submission' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    code_review = FactoryBot.create(:code_review, course: course)
    submission = FactoryBot.create(:submission, code_review: code_review, student: student)
    meeting_request_note = FactoryBot.create(:meeting_request_note, submission: submission)
    visit course_path(course)
    expect(page).to have_css('.glyphicon-comment')
  end

  scenario 'does not show icon when student has not requested a meeting for this submission' do
    student = FactoryBot.create(:student, :with_plan, course: course)
    code_review = FactoryBot.create(:code_review, course: course)
    submission = FactoryBot.create(:submission, code_review: code_review, student: student)
    visit course_path(course)
    expect(page).to_not have_css('.glyphicon-comment')
  end
end

feature 'exporting course students emails to a file' do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, :with_course) }
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

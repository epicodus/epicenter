feature 'Guest attempts to sign up' do
  scenario 'without an invitation' do
    visit new_student_registration_path
    expect(page).to have_content 'Sign up is only allowed via invitation.'
  end
end

feature 'Visiting students index page' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let(:admin) { student.course.admin }

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit course_path(student.course)
    expect(page).to have_content 'You are not authorized'
  end

  context 'as an admin' do
    before do
      login_as(admin, scope: :admin)
      visit course_path(student.course)
    end

    scenario 'viewing all students' do
      expect(page).to have_content admin.current_course.description
      expect(page).to have_content student.name
    end
  end
end

feature 'Student signs up via invitation', :vcr do
  context 'for portland or online student' do
    let(:course) { FactoryBot.create(:course, class_days: [Date.today.beginning_of_week + 5.weeks]) }
    let(:plan) { FactoryBot.create(:upfront_plan) }
    let(:student) { FactoryBot.create(:student, email: 'example@example.com', courses: [course], plan: plan) }

    scenario 'with valid information' do
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(page).to have_content 'Your password was set successfully. You are now signed in.'
      expect(Student.first.legal_name).to eq 'test legal name'
    end

    scenario 'saves legal name in Epicenter and CRM', :dont_stub_crm do
      close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
      lead_id = ENV['EXAMPLE_CRM_LEAD_ID']
      allow(CrmUpdateJob).to receive(:perform_later).and_return({})
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      expect(CrmUpdateJob).to receive(:perform_later).with(lead_id, { Rails.application.config.x.crm_fields['LEGAL_NAME'] => 'test legal name' })
      click_on 'Submit'
      expect(Student.first.legal_name).to eq 'test legal name'
    end

    scenario 'with missing information' do
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Password', with: ''
      click_on 'Submit'
      expect(page).to have_content 'error'
    end

    scenario 'without any documents signed goes to code of conduct' do
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_code_of_conduct_path
    end

    scenario 'with code of conduct signed goes to refund policy' do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_refund_policy_path
    end

    scenario 'with refund policy signed goes to enrollment agreement' do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_enrollment_agreement_path
    end

    scenario 'with enrollment agreement signed goes to demographics form' do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_demographic_path
    end

    context 'with demographics compmleted' do
      before do
        FactoryBot.create(:completed_code_of_conduct, student: student)
        FactoryBot.create(:completed_refund_policy, student: student)
        FactoryBot.create(:completed_enrollment_agreement, student: student)
        student.demographics = true
        student.save
      end

      scenario 'with payment due goes to payment page' do
        student.invite!
        visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
        fill_in 'Legal name', with: 'test legal name'
        fill_in 'Password', with: 'password'
        fill_in 'Password confirmation', with: 'password'
        click_on 'Submit'
        expect(current_path).to eq new_payment_method_path
      end

      scenario 'without payment due goes to course page' do
        allow_any_instance_of(Student).to receive(:upfront_amount_owed).and_return(0)
        student.invite!
        visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
        fill_in 'Legal name', with: 'test legal name'
        fill_in 'Password', with: 'password'
        fill_in 'Password confirmation', with: 'password'
        click_on 'Submit'
        expect(current_path).to eq student_courses_path(student)
      end

      scenario 'when requested 2fa enrollment' do
        student.invite!
        visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
        fill_in 'Legal name', with: 'test legal name'
        fill_in 'Password', with: 'password'
        fill_in 'Password confirmation', with: 'password'
        find('#twofa-checkbox').set true
        click_on 'Submit'
        expect(current_path).to eq new_otp_path
      end

      scenario 'when requested 2fa enrollment does not show navbar' do
        student.invite!
        visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
        fill_in 'Legal name', with: 'test legal name'
        fill_in 'Password', with: 'password'
        fill_in 'Password confirmation', with: 'password'
        find('#twofa-checkbox').set true
        click_on 'Submit'
        expect(page).to_not have_content 'Courses'
      end

      scenario 'when requested 2fa enrollment can cancel out' do
        student.invite!
        visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
        fill_in 'Legal name', with: 'test legal name'
        fill_in 'Password', with: 'password'
        fill_in 'Password confirmation', with: 'password'
        find('#twofa-checkbox').set true
        click_on 'Submit'
        click_on "Nevermind, I'll set this up later."
        expect(current_path).to eq new_payment_method_path
      end
    end
  end

  context 'for non-washingtonian' do
    let(:student) { FactoryBot.create(:student, :with_course, :with_plan, email: 'example@example.com') }

    scenario 'with other docs signed goes to demographics form' do
      allow_any_instance_of(Student).to receive(:washingtonian?).and_return false
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_demographic_path
    end
  end

  context 'for washingtonian in non-online cohort' do
    let(:student) { FactoryBot.create(:student, :with_course, :with_plan, email: 'example@example.com') }

    scenario 'with other docs signed goes to student complaint disclosure' do
      allow_any_instance_of(Student).to receive(:washingtonian?).and_return true
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_demographic_path
    end
  end

  context 'for washingtonian in online cohort' do
    let(:student) { FactoryBot.create(:online_student, :with_ft_online_cohort, :with_plan, email: 'example@example.com') }

    scenario 'with other docs signed goes to student complaint disclosure' do
      allow_any_instance_of(Student).to receive(:washingtonian?).and_return true
      FactoryBot.create(:completed_code_of_conduct, student: student)
      FactoryBot.create(:completed_refund_policy, student: student)
      FactoryBot.create(:completed_enrollment_agreement, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_complaint_disclosure_path
    end
  end

  context 'for Fidgetech student' do
    let(:fidgetech_course) { FactoryBot.create(:course, description: 'Fidgetech', class_days: [Date.today.beginning_of_week + 5.weeks]) }
    let(:plan) { FactoryBot.create(:upfront_plan) }
    let(:student) { FactoryBot.create(:student, email: 'example@example.com', courses: [fidgetech_course], plan: plan) }

    scenario 'with code of conduct signed goes to enrollment agreement' do
      FactoryBot.create(:completed_code_of_conduct, student: student)
      student.invite!
      visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
      fill_in 'Legal name', with: 'test legal name'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      click_on 'Submit'
      expect(current_path).to eq new_enrollment_agreement_path
    end
  end
end

feature 'Student signs in with GitHub' do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }

  after { OmniAuth.config.mock_auth[:github] = nil }

  scenario 'with valid credentials the first time' do
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with valid credentials on subsequent logins' do
    student = FactoryBot.create(:student, :with_all_documents_signed, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with a valid email but invalid uid on subsequent logins' do
    student = FactoryBot.create(:student, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '98765', info: { email: student.email }})
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
end

feature 'Student signs in with 2fa enabled' do
  let(:student_with_2fa) { FactoryBot.create(:student, :with_2fa, :with_all_documents_signed) }

  scenario 'unsuccessfully from root sign-in page when 2fa required but not entered' do
    visit root_path
    fill_in 'user_email', with: student_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to_not have_content 'Signed in successfully'
    click_on 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  scenario 'unsuccessfully from root sign-in page when incorrect 2fa code' do
    visit root_path
    fill_in 'user_email', with: student_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    expect(page).to_not have_content 'Signed in successfully'
    fill_in 'user_otp_attempt', with: 'wrong'
    click_on 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  scenario 'successfully from root sign-in page with 2fa code' do
    visit root_path
    fill_in 'user_email', with: student_with_2fa.email
    fill_in 'user_password', with: 'password'
    click_on 'Sign in'
    fill_in 'user_otp_attempt', with: student_with_2fa.current_otp
    click_on 'Sign in'
    expect(page).to have_content 'Signed in successfully'
  end
end

feature "Student signs in while class is not in session" do

  let(:future_course) { FactoryBot.create(:future_course) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: future_course) }

  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      sign_in_as(student)
      expect(page).to have_content "How would you like to make payments"
    end

    it "takes them to courses page if no payment due" do
      special_plan_student = FactoryBot.create(:student, :with_all_documents_signed, plan: FactoryBot.create(:special_plan), course: future_course)
      sign_in_as(special_plan_student)
      expect(page).to have_content "Your courses"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the payment methods page", :vcr do
      FactoryBot.create(:bank_account, student: student)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "Your payment methods"
      expect(page).to have_link "Verify Account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      FactoryBot.create(:verified_bank_account, student: student)
      sign_in_as(student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr, :stripe_mock do
    it "shows them their payment history" do
      FactoryBot.create(:credit_card, student: student)
      sign_in_as(student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payments"
    end
  end
end

feature "Student visits homepage after logged in" do
  it "takes student with payment due to the correct path" do
    student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, plan: FactoryBot.create(:upfront_plan))
    sign_in_as(student)
    visit root_path
    expect(current_path).to eq new_payment_method_path
    expect(page).to have_content "How would you like to make payments for the class?"
    expect(page).to_not have_content "Please make your remaining tuition payment as soon as possible."
  end

  it "shows alert if payment due and last week of intro" do
    student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, plan: FactoryBot.create(:upfront_plan))
    sign_in_as(student)
    travel_to student.course.end_date.beginning_of_week do
      visit root_path
      expect(page).to have_content "Please make your remaining tuition payment as soon as possible."
    end
  end

  it "does not show alert if not intro course" do
    student = FactoryBot.create(:student, :with_ft_cohort, plan: FactoryBot.create(:upfront_plan))
    sign_in_as(student)
    travel_to student.course.end_date.beginning_of_week do
      visit root_path
      expect(page).to_not have_content "Please make your remaining tuition payment as soon as possible."
    end
  end

  it "takes student with no payment due to the correct path" do
    student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, plan: FactoryBot.create(:special_plan))
    sign_in_as(student)
    visit root_path
    expect(current_path).to eq student_courses_path(student)
    expect(page).to have_content "Your courses"
  end

  it "does not show cohort name or cohort absences if not cohort" do
    student = FactoryBot.create(:student, :with_all_documents_signed, plan: FactoryBot.create(:special_plan))
    sign_in_as(student)
    visit root_path
    expect(current_path).to eq student_courses_path(student)
    expect(page).to_not have_content "Cohort:"
    expect(page).to_not have_content "Absences since the start of the current cohort"
    expect(page).to have_content "Absences ever at Epicodus"
    expect(page).to have_content "Number of Academic Warnings"
  end

  it "show cohort name and cohort absences when cohort listed" do
    student = FactoryBot.create(:student, :with_all_documents_signed, :with_pt_intro_cohort)
    sign_in_as(student)
    visit student_courses_path(student)
    expect(page).to have_content "Cohort:"
    expect(page).to have_content "Absences since the start of the current cohort"
    expect(page).to have_content "Absences ever at Epicodus"
    expect(page).to have_content "Number of Academic Warnings"
  end
end

feature "Unenrolled student signs in" do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }

  it "successfully and is redirected" do
    Enrollment.find_by(student_id: student.id, course_id: student.course.id).destroy
    sign_in_as(student)
    expect(current_path).to eq new_payment_method_path
    expect(page).to have_content 'Welcome to Epicodus'
  end
end

feature "Portland student signs in while class is in session" do
  let(:student) { FactoryBot.create(:portland_student, :with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }

  context "not at school" do
    it "takes them to the new payment method page" do
      sign_in_as(student)
      expect(current_path).to eq new_payment_method_path
      expect(page).to have_content "How would you like to make payments for the class?"
    end

    it "does not create an attendance record" do
      expect { sign_in_as(student) }.to change { AttendanceRecord.count }.by 0
    end
  end
end

feature "Philadelphia student signs in while class is in session" do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }

  context "not at school" do
    it "takes them to the new payment method page" do
      sign_in_as(student)
      expect(current_path).to eq new_payment_method_path
      expect(page).to have_content "How would you like to make payments for the class?"
    end

    it "does not create an attendance record" do
      expect { sign_in_as(student) }.to change { AttendanceRecord.count }.by 0
    end
  end
end

feature 'Guest not signed in' do
  subject { page }

  context 'visits new subscrition path' do
    before { visit new_bank_account_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_bank_account_path(1) }
    it { should have_content 'You need to sign in' }
  end

  context 'visits payments path' do
    let(:student) { FactoryBot.create(:student) }
    before { visit student_payments_path(student) }
    it { should have_content 'You need to sign in' }
  end
end

feature 'unenrolled student signs in' do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: []) }

  before { login_as(student, scope: :student) }

  it "takes them to the correct path" do
    visit root_path
    expect(current_path).to_not eq root_path
  end

  it 'student can view the payments page' do
    visit student_payments_path(student)
    expect(page).to have_content 'How would you like to make payments for the class?'
  end

  it 'student can view the profile page' do
    visit edit_student_registration_path(student)
    expect(page).to have_content 'Profile'
  end
end

feature 'viewing the student show page' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }

  before { login_as(student, scope: :student) }

  scenario 'as a student viewing their own page' do
    visit course_student_path(student.course, student)
    expect(page).to have_content student.course.description
  end

  scenario 'as a student viewing another student page in different course' do
    other_student = FactoryBot.create(:student, :with_course, :with_all_documents_signed)
    visit course_student_path(other_student.course, other_student)
    expect(page).to have_content 'You are not authorized to access this page.'
  end

  scenario 'as a student viewing another student page in same course' do
    other_student = FactoryBot.create(:student, :with_all_documents_signed, course: student.course)
    visit course_student_path(student.course, other_student)
    expect(page).to have_content 'You are not authorized to access this page.'
  end

  scenario 'when a student is enrolled in a course with code reviews' do
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

  scenario 'when a student is enrolled in a course with reflections' do
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

feature "shows warning if on probation" do
  context "when not on probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed)
      login_as(student, scope: :student)
      visit course_student_path(student.course, student)
      expect(page).to_not have_content "Academic Warning"
    end
  end

  context "when on teacher probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, probation_teacher: true)
      login_as(student, scope: :student)
      visit course_student_path(student.course, student)
      expect(page).to have_content "Academic Warning"
    end
  end

  context "when on advisor probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, probation_advisor: true)
      login_as(student, scope: :student)
      visit course_student_path(student.course, student)
      expect(page).to have_content "Academic Warning"
    end
  end
end

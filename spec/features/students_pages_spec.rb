feature 'Guest attempts to sign up' do
  scenario 'without an invitation' do
    visit new_student_registration_path
    expect(page).to have_content 'Sign up is only allowed via invitation.'
  end
end

feature 'Visiting students index page' do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
  let(:admin) { FactoryGirl.create(:admin) }

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

    scenario 'viewing paginated student list' do
      expect(page).to have_content admin.current_course.description
    end

    scenario 'viewing all students' do
      click_on 'View all'
      expect(page).to have_content admin.current_course.description
    end
  end
end

feature 'Student signs up via invitation', :vcr do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, email: 'test@test.com') }

  scenario 'with valid information' do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: 'Ryan Larson'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Submit'
    expect(page).to have_content 'Your password was set successfully. You are now signed in.'
  end

  scenario 'with missing information' do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: ''
    click_on 'Submit'
    expect(page).to have_content 'error'
  end
end

feature 'Student cannot invite other students' do
  let(:student) { FactoryGirl.create(:student) }

  scenario 'student visits new_student_invitation path' do
    login_as(student)
    visit new_student_invitation_path
    expect(page).to have_content 'You need to sign in or sign up before continuing'
  end
end

feature 'Student signs in with GitHub' do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  after { OmniAuth.config.mock_auth[:github] = nil }

  scenario 'with valid credentials the first time' do
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with valid credentials on subsequent logins' do
    student = FactoryGirl.create(:user_with_all_documents_signed, github_uid: '12345')
    OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
    visit root_path
    click_on 'Sign in with GitHub'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'with a valid email but invalid uid on subsequent logins' do
    student = FactoryGirl.create(:student, github_uid: '12345')
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

feature "Student signs in while class is not in session" do

  let(:future_course) { FactoryGirl.create(:future_course) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: future_course) }

  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      sign_in_as(student)
      visit new_payment_method_path
      expect(page).to have_content "How would you like to make payments"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the payment methods page", :vcr do
      FactoryGirl.create(:bank_account, student: student)
      sign_in_as student
      visit payment_methods_path
      expect(page).to have_content "Your payment methods"
      expect(page).to have_link "Verify Account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      FactoryGirl.create(:verified_bank_account, student: student)
      sign_in_as(student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr, :stripe_mock do
    it "shows them their payment history" do
      FactoryGirl.create(:credit_card, student: student)
      sign_in_as(student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payments"
    end
  end
end

feature "Student visits homepage after logged in" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  it "takes them to the correct path" do
    sign_in_as(student)
    visit root_path
    expect(current_path).to_not eq root_path
  end
end

feature "Unenrolled student signs in" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  it "successfully and is redirected" do
    Enrollment.find_by(student_id: student.id, course_id: student.course.id).destroy
    sign_in_as(student)
    expect(current_path).to eq new_payment_method_path
    expect(page).to have_content 'Welcome to Epicodus'
  end
end

feature "Portland student signs in while class is in session" do
  let(:student) { FactoryGirl.create(:portland_student_with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }

  context "not at school" do
    it "takes them to the courses page" do
      sign_in_as(student)
      expect(current_path).to eq student_courses_path(student)
      expect(page).to have_content "Your courses"
    end

    it "does not create an attendance record" do
      expect { sign_in_as(student) }.to change { AttendanceRecord.count }.by 0
    end
  end

  context "at school" do
    before do
      allow(IpLocation).to receive(:is_local?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(true)
    end

    context "when soloing" do
      it "takes them to the welcome page" do
        sign_in_as(student)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them during the week" do
        thursday = Time.zone.now.to_date.beginning_of_week + 3.days
        travel_to thursday do
          expect { sign_in_as(student) }.to change { student.attendance_records.count }.by 1
        end
      end

      it "does not create an attendance record for them on weekends" do
        allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(false)
        saturday = Time.zone.now.to_date.beginning_of_week + 5.days
        travel_to saturday do
          expect { sign_in_as(student) }.to change { student.attendance_records.count }.by 0
        end
      end

      it "takes them to the courses page if they've already signed in" do
        FactoryGirl.create(:attendance_record, student: student)
        sign_in_as(student)
        expect(current_path).to eq student_courses_path(student)
      end

      it 'does not update the attendance record on subsequent solo sign ins during the day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student)
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          visit root_path
          logout :student
          sign_in_as(student)
          expect(attendance_record.tardy).to be false
        end
      end
    end

    context 'when soloing and signing in with GitHub' do
      scenario 'creates an attendance record with valid credentials during the week' do
        travel_to Time.zone.now.to_date.beginning_of_week + 3.days do
          OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
          visit root_path
          expect { click_on('Sign in with GitHub') }.to change { student.attendance_records.count }.by 1
          expect(page).to have_content 'Signed in successfully and attendance record created.'
          OmniAuth.config.mock_auth[:github] = nil
        end
      end

      scenario 'does not create an attendance record on the weekend' do
        allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(false)
        travel_to Time.zone.now.to_date.beginning_of_week + 5.days do
          OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
          visit root_path
          expect { click_on('Sign in with GitHub') }.to change { student.attendance_records.count }.by 0
          expect(page).to have_content 'Signed in successfully.'
          OmniAuth.config.mock_auth[:github] = nil
        end
      end
    end

    context "when pairing on a school computer" do
      let(:pair) { FactoryGirl.create(:portland_student_with_all_documents_signed, password: 'password2', password_confirmation: 'password2') }

      before { allow(IpLocation).to receive(:is_local_computer?).and_return(true) }

      it "takes them to the welcome page" do
        sign_in_as(student, pair)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them" do
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.count }.by 2
      end

      it 'creates attendance records if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.count }.by 1
      end

      it 'updates the pair id if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.first.pair_id }.from(nil).to(pair.id)
      end

      it 'does not update the attendance record when signing as pairs, then solo during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student, pair)
        end
        attendance_record = AttendanceRecord.find_by(student: pair)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          sign_in_as(pair)
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing in solo, then as pairs, then solo again during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student)
          visit root_path
          logout :student
        end
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 10.hours do
          sign_in_as(student, pair)
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 14.hours do
          sign_in_as(student)
          expect(attendance_record.tardy).to be false
        end
      end

      it "gives an error for an incorrect email" do
        visit new_user_session_path
        fill_in 'user_email', with: 'wrong'
        fill_in 'user_password', with: student.password
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end

      it "gives an error for an incorrect password" do
        visit new_user_session_path
        fill_in 'user_email', with: student.email
        fill_in 'user_password', with: 'wrong'
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end
    end
  end
end

feature "Philadelphia student signs in while class is in session" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }

  context "not at school" do
    it "takes them to the courses page" do
      sign_in_as(student)
      expect(current_path).to eq student_courses_path(student)
      expect(page).to have_content "Your courses"
    end

    it "does not create an attendance record" do
      expect { sign_in_as(student) }.to change { AttendanceRecord.count }.by 0
    end
  end

  context "at school" do
    before do
      allow(IpLocation).to receive(:is_local?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(true)
    end

    context "when soloing" do
      it "takes them to the welcome page" do
        sign_in_as(student)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them during the week" do
        thursday = Time.zone.now.to_date.beginning_of_week + 3.days
        travel_to thursday do
          expect { sign_in_as(student) }.to change { student.attendance_records.count }.by 1
        end
      end

      it "does not create an attendance record for them on weekends" do
        allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(false)
        saturday = Time.zone.now.to_date.beginning_of_week + 5.days
        travel_to saturday do
          expect { sign_in_as(student) }.to change { student.attendance_records.count }.by 0
        end
      end

      it "takes them to the courses page if they've already signed in" do
        FactoryGirl.create(:attendance_record, student: student)
        sign_in_as(student)
        expect(current_path).to eq student_courses_path(student)
      end

      it 'does not update the attendance record on subsequent solo sign ins during the day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student)
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          visit root_path
          logout :student
          sign_in_as(student)
          expect(attendance_record.tardy).to be false
        end
      end
    end

    context 'when soloing and signing in with GitHub' do
      scenario 'creates an attendance record with valid credentials during the week' do
        travel_to Time.zone.now.to_date.beginning_of_week + 3.days do
          OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
          visit root_path
          expect { click_on('Sign in with GitHub') }.to change { student.attendance_records.count }.by 1
          expect(page).to have_content 'Signed in successfully and attendance record created.'
          OmniAuth.config.mock_auth[:github] = nil
        end
      end

      scenario 'does not create an attendance record on the weekend' do
        allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(false)
        travel_to Time.zone.now.to_date.beginning_of_week + 5.days do
          OmniAuth.config.add_mock(:github, { uid: '12345', info: { email: student.email }})
          visit root_path
          expect { click_on('Sign in with GitHub') }.to change { student.attendance_records.count }.by 0
          expect(page).to have_content 'Signed in successfully.'
          OmniAuth.config.mock_auth[:github] = nil
        end
      end
    end

    context "when pairing on a school computer" do
      let(:pair) { FactoryGirl.create(:user_with_all_documents_signed, password: 'password2', password_confirmation: 'password2') }

      before { allow(IpLocation).to receive(:is_local_computer?).and_return(true) }

      it "takes them to the welcome page" do
        sign_in_as(student, pair)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them" do
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.count }.by 2
      end

      it 'creates attendance records if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.count }.by 1
      end

      it 'updates the pair id if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { sign_in_as(student, pair) }.to change { AttendanceRecord.first.pair_id }.from(nil).to(pair.id)
      end

      it 'does not update the attendance record when signing as pairs, then solo during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student, pair)
        end
        attendance_record = AttendanceRecord.find_by(student: pair)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          sign_in_as(pair)
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing in solo, then as pairs, then solo again during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          sign_in_as(student)
          visit root_path
          logout :student
        end
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 10.hours do
          sign_in_as(student, pair)
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 14.hours do
          sign_in_as(student)
          expect(attendance_record.tardy).to be false
        end
      end

      it "gives an error for an incorrect email" do
        visit new_user_session_path
        fill_in 'user_email', with: 'wrong'
        fill_in 'user_password', with: student.password
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end

      it "gives an error for an incorrect password" do
        visit new_user_session_path
        fill_in 'user_email', with: student.email
        fill_in 'user_password', with: 'wrong'
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end
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
    let(:student) { FactoryGirl.create(:student) }
    before { visit student_payments_path(student) }
    it { should have_content 'You need to sign in' }
  end
end

feature 'unenrolled student signs in' do
  let(:student) { FactoryGirl.create(:unenrolled_student) }

  before { login_as(student, scope: :student) }

  it "takes them to the correct path" do
    visit root_path
    expect(current_path).to_not eq root_path
  end

  it 'student can view the payments page' do
    visit student_payments_path(student)
    expect(page).to have_content 'Your payment methods'
  end

  it 'student can view the profile page' do
    visit edit_student_registration_path(student)
    expect(page).to have_content 'Profile'
  end
end

feature 'viewing the student show page' do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  before { login_as(student, scope: :student) }

  scenario 'as a student viewing his/her own page' do
    visit course_student_path(student.course, student)
    expect(page).to have_content student.course.description
  end

  scenario 'as a student viewing another student page' do
    other_student = FactoryGirl.create(:user_with_all_documents_signed)
    visit course_student_path(other_student.course, other_student)
    expect(page).to have_content 'You are not authorized to access this page.'
  end
end

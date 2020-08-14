feature "remote attendance" do
  let(:student) { FactoryBot.create(:portland_student_with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }

  before { login_as(student, scope: :student) }

  describe 'sign in', :js do
    let!(:pair) { FactoryBot.create(:portland_student_with_all_documents_signed, courses: [student.course], password: 'password2', password_confirmation: 'password2') }

    it 'allows sign in solo' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select 'Solo', from: 'peer-eval-select-name'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in without a pair'
      end
    end

    it 'allows sign in with a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'peer-eval-select-name'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it "creates an attendance record with no pair id when signing in solo" do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select 'Solo', from: 'peer-eval-select-name'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in without a pair'
        expect(student.attendance_records.any?).to eq true
        expect(student.attendance_records.today.first.pair_id).to eq nil
      end
    end

    it 'creates an attendance record with a pair id when signing in with a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'peer-eval-select-name'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in with ' + pair.name
        expect(student.attendance_records.any?).to eq true
        expect(student.attendance_records.today.first.pair_id).to eq pair.id
      end
    end

    it 'does not show attendance today when course not in session' do
      travel_to student.course.start_date - 1.week do
        visit root_path
        expect(page).to_not have_content 'Attendance today'
      end
    end

    it 'redirects if student attempts to manually access sign_in path' do
      visit sign_in_path
      expect(page).to have_content 'Be sure Javascript is enabled'
    end
  end

  describe 'changing pair', :js do
    let!(:pair) { FactoryBot.create(:portland_student_with_all_documents_signed, courses: [student.course], password: 'password2', password_confirmation: 'password2') }

    it 'allows changing from solo to a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'attendance-change-pair-link'
        select pair.name, from: 'peer-eval-select-name'
        click_button 'Change pair'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it 'allows changing from one pair to another' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student, pair: FactoryBot.create(:student))
        visit root_path
        click_link 'attendance-change-pair-link'
        select pair.name, from: 'peer-eval-select-name'
        click_button 'Change pair'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it 'does not show sign in link when student already signed in' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        expect(page).to_not have_content 'Sign in'
        expect(page).to have_content 'Signed in:'
      end
    end
  end

  describe 'signing out' do
    it 'allows signing out from link in attendance box' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'attendance-sign-out-link'
        expect(page).to have_content 'Only Epicodus staff will see your pair feedback'
      end
    end

    it 'allows signing out of attendance from navbar' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'Attendance'
        expect(page).to have_content 'Only Epicodus staff will see your pair feedback'
      end
    end

    it 'allows signing out of Epicenter from navbar' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'Epicenter'
        expect(page).to have_content 'Signed out successfully.'
      end
    end

    it 'does not show sign out link when student already signed out' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student, signed_out_time: Time.zone.now)
        visit root_path
        expect(page).to_not have_content 'attendance-sign-out-link'
        expect(page).to have_content 'Signed out:'
      end
    end

    it 'does not show navbar sign out link when student already signed out' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student, signed_out_time: Time.zone.now)
        visit root_path
        expect(page).to_not have_content 'Epicenter'
      end
    end

    it 'does not allow sign out if not signed in yet' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit '/sign_out'
        expect(page).to have_content "You haven't signed in yet today"
      end
    end
  end

  describe 'when class not in session', :dont_stub_students_in_classroom do
    it 'shows attendance box when class day and time' do
      travel_to student.course.start_date.beginning_of_day + 10.hours do
        visit root_path
        expect(page).to have_content 'Sign in'
      end
    end

    it 'does not show attendance box when not class day' do
      travel_to student.course.start_date - 1.week do
        visit root_path
        expect(page).to_not have_content 'Sign in'
      end
    end

    it 'does not show sign in link before class time' do
      travel_to student.course.start_date.beginning_of_day do
        visit root_path
        expect(page).to have_content 'Sign in will be available at'
      end
    end

    it 'does not show sign in link after class time' do
      travel_to student.course.start_date.beginning_of_day + 20.hours do
        visit root_path
        expect(page).to have_content 'Sign in is not available after class end time'
      end
    end
  end
end

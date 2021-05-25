feature "remote attendance" do
  let(:student) { FactoryBot.create(:portland_student, :with_all_documents_signed) }

  before { login_as(student, scope: :student) }

  describe 'sign in', :js do
    let!(:pair) { FactoryBot.create(:portland_student, :with_all_documents_signed, courses: [student.course]) }

    it 'allows sign in solo' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select '-', from: 'pair-select-1'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in without a pair'
      end
    end

    it 'allows sign in with a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it 'allows sign in with group of 3' do
      pair2 = FactoryBot.create(:student, courses: [student.course])
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        select pair2.name, from: 'pair-select-2'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with" #{pair.name} & #{pair2.name}"
        expect(page).to have_content pair.name
        expect(page).to have_content pair2.name
      end
    end

    it 'allows sign in with group of 4' do
      pair2 = FactoryBot.create(:student, courses: [student.course])
      pair3 = FactoryBot.create(:student, courses: [student.course])
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        select pair2.name, from: 'pair-select-2'
        select pair3.name, from: 'pair-select-3'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with"
        expect(page).to have_content pair.name
        expect(page).to have_content pair2.name
        expect(page).to have_content pair3.name
      end
    end

    it 'allows sign in with group of 5' do
      pair2 = FactoryBot.create(:student, courses: [student.course])
      pair3 = FactoryBot.create(:student, courses: [student.course])
      pair4 = FactoryBot.create(:student, courses: [student.course])
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        select pair2.name, from: 'pair-select-2'
        select pair3.name, from: 'pair-select-3'
        select pair4.name, from: 'pair-select-4'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with"
        expect(page).to have_content pair.name
        expect(page).to have_content pair2.name
        expect(page).to have_content pair3.name
        expect(page).to have_content pair4.name
      end
    end

    it 'removes 2nd pair if same as 1st pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        select pair.name, from: 'pair-select-2'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with #{pair.name}"
        expect(page).to_not have_content "You are signed in with #{pair.name} & #{pair.name}"
      end
    end

    it 'assigns 2nd pair if 1st pair field blank' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select '-', from: 'pair-select-1'
        select pair.name, from: 'pair-select-2'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with #{pair.name}"
      end
    end

    it "creates an attendance record with no pair id when signing in solo" do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select '-', from: 'pair-select-1'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in without a pair'
        expect(student.attendance_records.any?).to eq true
        expect(student.attendance_records.today.first.pairings.pluck(:pair_id)).to eq []
      end
    end

    it 'creates an attendance record with a pair id when signing in with a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        click_button 'Sign in'
        expect(page).to have_content 'You are signed in with ' + pair.name
        expect(student.attendance_records.any?).to eq true
        expect(student.attendance_records.today.first.pairings.pluck(:pair_id)).to eq [pair.id]
      end
    end

    it 'creates an attendance record with both pair ids when signing in as group of 3' do
      pair2 = FactoryBot.create(:student, courses: [student.course])
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        visit root_path
        click_link 'attendance-sign-in-link'
        select pair.name, from: 'pair-select-1'
        select pair2.name, from: 'pair-select-2'
        click_button 'Sign in'
        expect(page).to have_content "You are signed in with"
        expect(page).to have_content pair.name
        expect(page).to have_content pair2.name
        expect(student.attendance_records.any?).to eq true
        expect(student.attendance_records.today.first.pairings.pluck(:pair_id)).to include pair.id
        expect(student.attendance_records.today.first.pairings.pluck(:pair_id)).to include pair2.id
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
    let!(:pair) { FactoryBot.create(:portland_student, :with_all_documents_signed, courses: [student.course], password: 'password2', password_confirmation: 'password2') }

    it 'allows changing from solo to a pair' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'attendance-change-pair-link'
        select pair.name, from: 'pair-select-1'
        click_button 'Change pair'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it 'allows changing from one pair to another' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        attendance_record = FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: FactoryBot.create(:student).id])
        visit root_path
        click_link 'attendance-change-pair-link'
        select pair.name, from: 'pair-select-1'
        click_button 'Change pair'
        expect(page).to have_content 'You are signed in with ' + pair.name
      end
    end

    it 'allows changing from one pair to group of 3' do
      pair2 = FactoryBot.create(:student, courses: [student.course])
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        attendance_record = FactoryBot.create(:attendance_record, student: student, pairings_attributes: [pair_id: FactoryBot.create(:student).id])
        visit root_path
        click_link 'attendance-change-pair-link'
        select pair.name, from: 'pair-select-1'
        select pair2.name, from: 'pair-select-2'
        click_button 'Change pair'
        expect(page).to have_content "You are signed in with"
        expect(page).to have_content pair.name
        expect(page).to have_content pair2.name
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

  describe 'shows list of nonreciprocated pairs' do
    let(:other_student) { FactoryBot.create(:student, :with_course) }

    it 'does not show when not signed in' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: other_student, pairings_attributes: [pair_id: student.id])
        visit root_path
        expect(page).to_not have_content "Additional students have marked you as a pair today"
      end
    end

    it 'shows when signed in' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: other_student, pairings_attributes: [pair_id: student.id])
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        expect(page).to have_content "Additional students have marked you as a pair today: #{other_student.name}"
      end
    end

    it 'does not show when no nonreciprocated pairs' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        expect(page).to_not have_content "Additional students have marked you as a pair today"
      end
    end
  end

  describe 'signing out' do
    it 'allows signing out from link in attendance box' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'attendance-sign-out-link'
        expect(page).to have_content 'Attendance sign out'
      end
    end

    it 'allows signing out of attendance from navbar' do
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        FactoryBot.create(:attendance_record, student: student)
        visit root_path
        click_link 'Attendance'
        expect(page).to have_content 'Attendance sign out'
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

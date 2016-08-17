feature "Student does attendance sign in" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, password: 'password1', password_confirmation: 'password1') }
  let(:pair) { FactoryGirl.create(:user_with_all_documents_signed, password: 'password2', password_confirmation: 'password2') }

  def attendance_sign_in_solo
    visit sign_in_path
    fill_in 'email1', with: student.email
    fill_in 'password1', with: student.password
    click_button 'Attendance sign in'
  end

  def attendance_sign_in_pair
    visit sign_in_path
    fill_in 'email1', with: student.email
    fill_in 'password1', with: student.password
    fill_in 'email2', with: pair.email
    fill_in 'password2', with: pair.password
    click_button 'Attendance sign in'
  end

  context "not at school" do
    it "does not show attendance sign in page" do
      allow(IpLocation).to receive(:is_local?).and_return(false)
      allow(IpLocation).to receive(:is_local_computer?).and_return(false)
      visit sign_in_path
      expect(page).to have_content "Attendance sign in unavailable."
    end
  end

  context "not a weekday" do
    it "does not show attendance sign in page" do
      allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(false)
      visit sign_in_path
      expect(page).to have_content "Attendance sign in unavailable."
    end
  end

  context "a weekday at school" do
    before do
      allow(IpLocation).to receive(:is_local?).and_return(true)
      allow(IpLocation).to receive(:is_local_computer?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:is_weekday?).and_return(true)
    end

    it "shows attendance sign in page" do
      visit sign_in_path
      expect(page).to have_content "first student"
    end

    context "when soloing" do
      context "incorrect login credentials" do
        it "gives an error for an incorrect email" do
          visit sign_in_path
          fill_in 'email1', with: 'wrong'
          fill_in 'password1', with: student.password
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid email or password.'
        end

        it "gives an error for an incorrect password" do
          visit sign_in_path
          fill_in 'email1', with: student.email
          fill_in 'password1', with: 'wrong'
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid email or password.'
        end
      end

      it "takes them to the welcome page" do
        attendance_sign_in_solo
        expect(current_path).to eq welcome_path
        expect(page).to have_content 'Your attendance record has been created.'
      end

      it "creates an attendance record for them" do
        thursday = Time.zone.now.to_date.beginning_of_week + 3.days
        travel_to thursday do
          expect { attendance_sign_in_solo }.to change { student.attendance_records.count }.by 1
        end
      end

      it 'does not update the attendance record on subsequent solo sign ins during the day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          attendance_sign_in_solo
          expect(attendance_record.tardy).to be false
          expect(AttendanceRecord.count).to equal 1
        end
      end
    end

    context "when pairing" do
      context "incorrect login credentials" do
        it "gives an error for an incorrect email1" do
          visit sign_in_path
          fill_in 'email1', with: 'wrong'
          fill_in 'password1', with: student.password
          fill_in 'email2', with: pair.email
          fill_in 'password2', with: pair.password
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid login credentials.'
        end

        it "gives an error for an incorrect email2" do
          visit sign_in_path
          fill_in 'email1', with: student.email
          fill_in 'password1', with: student.password
          fill_in 'email2', with: 'wrong'
          fill_in 'password2', with: pair.password
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid login credentials.'
        end

        it "gives an error for an incorrect password1" do
          visit sign_in_path
          fill_in 'email1', with: student.email
          fill_in 'password1', with: 'wrong'
          fill_in 'email2', with: pair.email
          fill_in 'password2', with: pair.password
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid login credentials.'
        end

        it "gives an error for an incorrect password1" do
          visit sign_in_path
          fill_in 'email1', with: student.email
          fill_in 'password1', with: student.password
          fill_in 'email2', with: pair.email
          fill_in 'password2', with: 'wrong'
          click_button 'Attendance sign in'
          expect(page).to have_content 'Invalid login credentials.'
        end
      end

      it "takes them to the welcome page" do
        attendance_sign_in_pair
        expect(current_path).to eq welcome_path
        expect(page).to have_content 'Your attendance records have been created.'
      end

      it "creates attendance records for both students" do
        thursday = Time.zone.now.to_date.beginning_of_week + 3.days
        travel_to thursday do
          attendance_sign_in_pair
          expect(AttendanceRecord.count).to equal 2
        end
      end

      it 'creates attendance records if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { attendance_sign_in_pair }.to change { AttendanceRecord.count }.by 1
      end

      it 'updates the pair id if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { attendance_sign_in_pair }.to change { AttendanceRecord.first.pair_id }.from(nil).to(pair.id)
      end

      it 'does not update the attendance record when signing as pairs, then solo during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: pair)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          sign_in_as(pair)
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing as solo, then pair during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 12.hours do
          attendance_sign_in_pair
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing in solo, then as pairs, then solo again during same day' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 8.hours do
          attendance_sign_in_solo
        end
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 10.hours do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 14.hours do
          attendance_sign_in_solo
          expect(attendance_record.tardy).to be false
        end
      end
    end
  end
end

feature "Portland student does attendance sign in", :dont_stub_class_times do
  let(:portland_office) { FactoryBot.create(:portland_office) }
  let(:course) { FactoryBot.create(:course, :with_ft_class_times, office: portland_office) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: course, password: 'password1', password_confirmation: 'password1') }
  let(:pair) { FactoryBot.create(:student, :with_all_documents_signed, course: course, password: 'password2', password_confirmation: 'password2') }
  let(:start_date_start_time) { student.course.start_time_on_day(student.course.start_date) }

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
    it "does not show in-person attendance sign in page" do
      allow(IpLocation).to receive(:is_local?).and_return(false)
      visit sign_in_path
      expect(page).to have_content "Attendance sign in unavailable. If you are an online student, please sign into attendance through Epicenter."
    end
  end

  context "at school" do
    before { allow(IpLocation).to receive(:is_local?).and_return(true) }

    it "shows attendance sign in page" do
      visit sign_in_path
      expect(page).to have_content "first student"
    end

    context "when soloing" do
      context "incorrect login credentials" do
        it "gives an error for an incorrect email" do
          travel_to start_date_start_time do
            visit sign_in_path
            fill_in 'email1', with: 'wrong'
            fill_in 'password1', with: student.password
            click_button 'Attendance sign in'
            expect(page).to have_content 'Invalid login credentials.'
          end
        end

        it "gives an error for an incorrect password" do
          travel_to start_date_start_time do
            visit sign_in_path
            fill_in 'email1', with: student.email
            fill_in 'password1', with: 'wrong'
            click_button 'Attendance sign in'
            expect(page).to have_content 'Invalid login credentials.'
          end
        end
      end

      it "redirects if sign in attempt on a Friday" do
        travel_to start_date_start_time + 4.days do
          attendance_sign_in_solo
          expect(current_path).to eq root_path
          expect(page).to have_content 'Attendance sign in not required on Fridays.'
        end
      end

      it "redirects if not a class day" do
        travel_to start_date_start_time + 5.days do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "redirects if on a class day but before class sign in available" do
        travel_to start_date_start_time - 1.hour do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "redirects if on a class day but after class end time" do
        travel_to start_date_start_time + 9.hours + 5.minutes do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "takes them to the welcome page during class time" do
        travel_to start_date_start_time do
          attendance_sign_in_solo
          expect(current_path).to eq welcome_path
          expect(page).to have_content 'Your sign in time has been recorded'
        end
      end

      it "takes them to the welcome page if sign in just before class time" do
        travel_to start_date_start_time - 25.minutes do
          attendance_sign_in_solo
          expect(current_path).to eq welcome_path
          expect(page).to have_content 'Your sign in time has been recorded'
        end
      end

      it "creates an attendance record for them" do
        travel_to start_date_start_time do
          expect { attendance_sign_in_solo }.to change { student.attendance_records.count }.by 1
        end
      end

      it 'does not update the attendance record on subsequent solo sign ins during the day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        travel_to start_date_start_time + 4.hours do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        expect(attendance_record.tardy).to be false
        expect(AttendanceRecord.count).to equal 1
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

      it "redirects if sign in attempt on a Friday" do
        travel_to start_date_start_time + 4.days do
          attendance_sign_in_pair
          expect(current_path).to eq root_path
          expect(page).to have_content 'Attendance sign in not required on Fridays.'
        end
      end

      it "redirects if not a class day for student 1" do
        travel_to start_date_start_time - 1.day do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "redirects if not a class day for student 2" do
        pt_course = FactoryBot.create(:part_time_course, :with_pt_class_times, office: course.office)
        pt_student = FactoryBot.create(:student, :with_all_documents_signed, course: pt_course, password: 'password1', password_confirmation: 'password1')
        travel_to start_date_start_time do
          visit sign_in_path
          fill_in 'email1', with: pt_student.email
          fill_in 'password1', with: pt_student.password
          click_button 'Attendance sign in'
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{pt_student.name}. No attendance records created."
        end
      end

      it "redirects if class day for first student but not second" do
        pt_course = FactoryBot.create(:part_time_course, :with_pt_class_times, office: course.office)
        pt_student = FactoryBot.create(:student, :with_all_documents_signed, course: pt_course, password: 'password1', password_confirmation: 'password1')
        travel_to start_date_start_time do
          visit sign_in_path
          fill_in 'email1', with: student.email
          fill_in 'password1', with: student.password
          fill_in 'email2', with: pt_student.email
          fill_in 'password2', with: pt_student.password
          click_button 'Attendance sign in'
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{pt_student.name}. No attendance records created."
        end
      end

      it "redirects if class day for second student but not first" do
        pt_course = FactoryBot.create(:part_time_course, :with_pt_class_times, office: course.office)
        pt_student = FactoryBot.create(:student, :with_all_documents_signed, course: pt_course, password: 'password1', password_confirmation: 'password1')
        travel_to start_date_start_time do
          visit sign_in_path
          fill_in 'email1', with: pt_student.email
          fill_in 'password1', with: pt_student.password
          fill_in 'email2', with: student.email
          fill_in 'password2', with: student.password
          click_button 'Attendance sign in'
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{pt_student.name}. No attendance records created."
        end
      end

      it "takes them to the welcome page" do
        travel_to start_date_start_time do
          attendance_sign_in_pair
          expect(current_path).to eq welcome_path
          expect(page).to have_content "Your sign in times have been recorded as 08:00 AM (#{student.name}) and 08:00 AM (#{pair.name})"
        end
      end

      it "creates attendance records for both students" do
        travel_to start_date_start_time do
          attendance_sign_in_pair
          expect(AttendanceRecord.count).to equal 2
        end
      end

      it 'creates attendance records if one student has already signed in for the day' do
        travel_to start_date_start_time do
          FactoryBot.create(:attendance_record, student: student)
          expect { attendance_sign_in_pair }.to change { AttendanceRecord.count }.by 1
        end
      end

      it 'updates the pair id if one student has already signed in for the day' do
        travel_to start_date_start_time do
          FactoryBot.create(:attendance_record, student: student)
          expect { attendance_sign_in_pair }.to change { student.pair_ids.first }.from(nil).to(pair.id)
        end
      end

      it 'does not update the attendance record when signing as pairs, then solo during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: pair)
        travel_to start_date_start_time + 4.hours do
          sign_in_as(pair)
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing as solo, then pair during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to start_date_start_time + 4.hours do
          attendance_sign_in_pair
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record sign in time when signing in solo, then as pairs, then solo again during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        travel_to start_date_start_time + 2.hours do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to start_date_start_time + 6.hours do
          attendance_sign_in_solo
          expect(attendance_record.tardy).to be false
        end
      end
    end
  end
end

feature "Philadelphia student does attendance sign in", :dont_stub_class_times do
  let(:philadelphia_office) { FactoryBot.create(:philadelphia_office) }
  let(:course) { FactoryBot.create(:course, :with_ft_class_times, office: philadelphia_office) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: course, password: 'password1', password_confirmation: 'password1') }
  let(:pair) { FactoryBot.create(:student, :with_all_documents_signed, course: course, password: 'password2', password_confirmation: 'password2') }
  let(:start_date_start_time) { student.course.start_time_on_day(student.course.start_date) }

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
      visit sign_in_path
      expect(page).to have_content "Attendance sign in unavailable."
    end
  end

  context "at school" do
    before { allow(IpLocation).to receive(:is_local?).and_return(true) }

    it "shows attendance sign in page" do
      visit sign_in_path
      expect(page).to have_content "first student"
    end

    context "when soloing" do
      context "incorrect login credentials" do
        it "gives an error for an incorrect email" do
          travel_to start_date_start_time do
            visit sign_in_path
            fill_in 'email1', with: 'wrong'
            fill_in 'password1', with: student.password
            click_button 'Attendance sign in'
            expect(page).to have_content 'Invalid login credentials.'
          end
        end

        it "gives an error for an incorrect password" do
          travel_to start_date_start_time do
            visit sign_in_path
            fill_in 'email1', with: student.email
            fill_in 'password1', with: 'wrong'
            click_button 'Attendance sign in'
            expect(page).to have_content 'Invalid login credentials.'
          end
        end
      end

      it "redirects if sign in attempt on a Friday" do
        travel_to start_date_start_time + 4.days do
          attendance_sign_in_solo
          expect(current_path).to eq root_path
          expect(page).to have_content 'Attendance sign in not required on Fridays.'
        end
      end

      it "redirects if not a class day" do
        travel_to start_date_start_time - 1.day do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "takes them to the welcome page" do
        travel_to start_date_start_time do
          attendance_sign_in_solo
          expect(current_path).to eq welcome_path
          expect(page).to have_content 'Your sign in time has been recorded'
        end
      end

      it "creates an attendance record for them" do
        travel_to start_date_start_time do
          expect { attendance_sign_in_solo }.to change { student.attendance_records.count }.by 1
        end
      end

      it 'does not update the attendance record on subsequent solo sign ins during the day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to start_date_start_time + 4.hours do
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

      it "redirects if sign in attempt on a Friday" do
        travel_to start_date_start_time + 4.days do
          attendance_sign_in_pair
          expect(current_path).to eq root_path
          expect(page).to have_content 'Attendance sign in not required on Fridays.'
        end
      end

      it "redirects if not a class day for a student" do
        travel_to start_date_start_time - 1.day do
          attendance_sign_in_solo
          expect(current_path).to eq sign_in_classroom_path
          expect(page).to have_content "Class is not currently in session for #{student.name}. No attendance records created."
        end
      end

      it "takes them to the welcome page" do
        travel_to start_date_start_time do
          attendance_sign_in_pair
          expect(current_path).to eq welcome_path
          expect(page).to have_content "Your sign in times have been recorded as 05:00 AM (#{student.name}) and 05:00 AM (#{pair.name}"
        end
      end

      it "creates attendance records for both students" do
        travel_to start_date_start_time do
          attendance_sign_in_pair
          expect(AttendanceRecord.count).to equal 2
        end
      end

      it 'creates attendance records if one student has already signed in for the day' do
        travel_to start_date_start_time do
          FactoryBot.create(:attendance_record, student: student)
          expect { attendance_sign_in_pair }.to change { AttendanceRecord.count }.by 1
        end
      end

      it 'updates the pair id if one student has already signed in for the day' do
        travel_to start_date_start_time do
          FactoryBot.create(:attendance_record, student: student)
          expect { attendance_sign_in_pair }.to change { student.pair_ids.first }.from(nil).to(pair.id)
        end
      end

      it 'does not update the attendance record when signing as pairs, then solo during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: pair)
        travel_to start_date_start_time + 4.hours do
          sign_in_as(pair)
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing as solo, then pair during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to start_date_start_time + 4.hours do
          attendance_sign_in_pair
          expect(attendance_record.tardy).to be false
        end
      end

      it 'does not update the attendance record when signing in solo, then as pairs, then solo again during same day' do
        travel_to start_date_start_time do
          attendance_sign_in_solo
        end
        travel_to start_date_start_time + 2.hours do
          attendance_sign_in_pair
        end
        attendance_record = AttendanceRecord.find_by(student: student)
        travel_to start_date_start_time + 6.hours do
          attendance_sign_in_solo
          expect(attendance_record.tardy).to be false
        end
      end
    end
  end
end


feature 'help queue link' do
  describe "links to help queue for correct office" do
    it "links to Seattle queue if connecting from Seattle IP" do
      allow(IpLocation).to receive(:is_local_computer_seattle?).and_return(true)
      visit welcome_path
      expect(page).to have_link("Queue", href: "https://seattle-help.epicodus.com")
    end

    it "links to Portland queue unless connecting from Seattle IP" do
      allow(IpLocation).to receive(:is_local_computer_seattle?).and_return(false)
      visit welcome_path
      expect(page).to have_link("Queue", href: "https://help.epicodus.com")
    end
  end
end

feature 'student signing out on attendance page' do
  let(:portland_office) { FactoryBot.create(:portland_office) }
  let(:course) { FactoryBot.create(:course, :with_ft_class_times, office: portland_office) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: course) }
  let(:start_date_start_time) { student.course.start_time_on_day(student.course.start_date) }

  before do
    allow(IpLocation).to receive(:is_local?).and_return(true)
  end

  context 'when paired' do
    let(:pair) { FactoryBot.create(:student, courses: [student.course]) }

    scenario 'signing out from attendance box does not direct to pair feedback' do
      travel_to student.course.start_date + 8.hours do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date, pairings_attributes: [pair_id: pair.id])
        login_as(student, scope: :student)
        visit root_path  
        click_link 'attendance-sign-out-link'
        expect(page).to_not have_content 'Only Epicodus staff will see your pair feedback'
        expect(current_path).to eq sign_out_classroom_path
        expect(page).to have_content 'Attendance sign out'
      end
    end

    scenario 'shows link for pair feedback' do
      travel_to student.course.start_date + 8.hours do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date, pairings_attributes: [pair_id: pair.id])
        login_as(student, scope: :student)
        visit root_path  
        click_on 'Pair feedback'
        expect(page).to have_content 'Only Epicodus staff will see your pair feedback'
      end
    end
  end

  scenario 'student successfully signs out' do
    travel_to start_date_start_time do
      FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
      visit sign_out_path
      fill_in "email", with: student.email
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to have_content "Goodbye #{student.name}"
    end
  end

  scenario 'student successfully signs out with an uppercased email' do
    travel_to start_date_start_time do
      FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
      visit sign_out_path
      fill_in "email", with: student.email.upcase
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to have_content "Goodbye #{student.name}"
    end
  end

  scenario 'student fails to log out because they have not logged in yet' do
    travel_to start_date_start_time do
      visit sign_out_path
      fill_in "email", with: student.email
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to have_content "You haven't signed in yet today."
    end
  end

  scenario 'student fails to log out because the wrong password is used' do
    travel_to start_date_start_time do
      visit sign_out_path
      fill_in "email", with: student.email
      fill_in "password", with: "wrong_password"
      click_button "Attendance sign out"
      expect(page).to have_content 'Invalid email or password'
    end
  end

  scenario 'student fails to log out because the wrong email is used' do
    travel_to start_date_start_time do
      visit sign_out_path
      fill_in "email", with: 'wrong_email@epicodus.com'
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to have_content 'Invalid email or password'
    end
  end

  scenario 'student does not see Epicenter sign out reminder when not signed into Epicenter' do
    travel_to start_date_start_time do
      visit sign_out_path
      fill_in "email", with: student.email.upcase
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to_not have_content "Don't forget to sign out of"
    end
  end

  scenario 'student sees Epicenter sign out reminder when signed into Epicenter' do
    travel_to start_date_start_time do
      FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
      login_as(student, scope: :student)
      visit sign_out_path
      fill_in "email", with: student.email.upcase
      fill_in "password", with: student.password
      click_button "Attendance sign out"
      expect(page).to have_content "Don't forget to sign out of"
    end
  end
end

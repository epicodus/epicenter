feature "creating an attendance record amendment" do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  context "as an admin" do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

    before do
      login_as(admin, scope: :admin)
    end

    scenario "when a new record needs to be created" do
      visit new_attendance_record_amendment_path
      select student.name, from: "attendance_record_amendment_student_id"
      fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
      select "On time", from: "attendance_record_amendment_status"
      click_button "Submit"
      attendance_record = AttendanceRecord.last
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to"
    end

    scenario "when a new record needs to be created" do
      visit new_attendance_record_amendment_path
      select student.name, from: "attendance_record_amendment_student_id"
      fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
      select "Tardy and Left early", from: "attendance_record_amendment_status"
      click_button "Submit"
      attendance_record = AttendanceRecord.last
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to"
      expect(page).to have_content 'Tardy'
      expect(page).to have_content 'Left early'
      expect(page).to_not have_content 'On time'
    end

    scenario "changing pair to solo" do
      visit new_attendance_record_amendment_path
      select student.name, from: "attendance_record_amendment_student_id"
      fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
      select "On time", from: "attendance_record_amendment_status"
      select "Solo", from: "Pair"
      click_button "Submit"
      attendance_record = AttendanceRecord.last
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to"
      expect(page).to have_content "Solo"
    end

    scenario "changing pair to another student" do
      pair = FactoryBot.create(:student, courses: [student.course])
      visit new_attendance_record_amendment_path
      select student.name, from: "attendance_record_amendment_student_id"
      fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
      select "On time", from: "attendance_record_amendment_status"
      select pair.name, from: "Pair"
      click_button "Submit"
      attendance_record = AttendanceRecord.last
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to"
      expect(page).to have_content pair.name
    end

    scenario "adjusting existing attendance record pair only" do
      pair = FactoryBot.create(:student, courses: [student.course])
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, tardy: true)
      visit student_attendance_records_path(student)
      all('.edit-attendance').last.click_link('Edit')
      select pair.name, from: "Pair"
      click_button "Submit"
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to #{attendance_record.status}"
      expect(page).to have_content pair.name
    end

    scenario "adjusting existing attendance record attendance status only" do
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, tardy: true)
      visit student_attendance_records_path(student)
      all('.edit-attendance').last.click_link('Edit')
      select "Tardy and Left early", from: "attendance_record_amendment_status"
      click_button "Submit"
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to Tardy and Left early"
    end

    scenario "deleting existing attendance record" do
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, tardy: true)
      visit student_attendance_records_path(student)
      all('.edit-attendance').last.click_link('Edit')
      select "Absent", from: "attendance_record_amendment_status"
      click_button "Submit"
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to Absent"
      expect(AttendanceRecord.exists?(attendance_record.id)).to eq false
    end

    scenario 'with errors' do
      visit new_attendance_record_amendment_path
      click_button "Submit"
      expect(page).to have_content "can't be blank"
    end
  end

  context 'as a student' do
    before do
      login_as(student, scope: :student)
    end

    scenario "trying to view attendance record amendment form" do
      visit new_attendance_record_amendment_path
      expect(page).to have_content "You are not authorized to access this page."
    end
  end

end

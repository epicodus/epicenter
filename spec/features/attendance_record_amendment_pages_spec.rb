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

    scenario "changing pair to group of 3" do
      pair = FactoryBot.create(:student, courses: [student.course])
      pair2 = FactoryBot.create(:student, courses: [student.course])
      visit new_attendance_record_amendment_path
      select student.name, from: "attendance_record_amendment_student_id"
      fill_in "attendance_record_amendment_date", with: student.course.start_date.strftime("%F")
      select "On time", from: "attendance_record_amendment_status"
      select pair.name, from: "Pair"
      select pair2.name, from: "Pair2"
      click_button "Submit"
      attendance_record = AttendanceRecord.last
      expect(page).to have_content "The attendance record for #{student.name} on #{attendance_record.date.to_date.strftime('%A, %B %d, %Y')} has been amended to"
      expect(page).to have_content pair.name
      expect(page).to have_content pair2.name
      expect(attendance_record.pair).to eq pair
      expect(attendance_record.pair2).to eq pair2
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

feature "creating an attendance record amendment from the day attendance page", :js do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  context "as an admin" do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
    before { login_as(admin, scope: :admin) }

    scenario "when a new record needs to be created" do
      visit course_day_attendance_records_path(student.course, day: student.course.start_date)
      select "On time", from: student.id.to_s
      wait_for_ajax
      expect(student.attendance_record_on_day(student.course.start_date).status).to eq 'On time'
      expect(page).to have_css('.label-success', text: 'On time')
    end

    scenario "when marking a student as tardy" do
      visit course_day_attendance_records_path(student.course, day: student.course.start_date)
      select "Tardy", from: student.id.to_s
      wait_for_ajax
      expect(student.attendance_record_on_day(student.course.start_date).status).to eq 'Tardy'
      expect(page).to have_css('.label-danger', text: 'Tardy')
    end

    scenario "when marking a student as left early" do
      visit course_day_attendance_records_path(student.course, day: student.course.start_date)
      select "Left early", from: student.id.to_s
      wait_for_ajax
      expect(student.attendance_record_on_day(student.course.start_date).status).to eq 'Left early'
      expect(page).to have_css('.label-danger', text: 'Left early')
    end

    scenario "when marking a student as absent" do
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, tardy: true)
      visit course_day_attendance_records_path(student.course, day: student.course.start_date)
      select "Absent", from: student.id.to_s
      wait_for_ajax
      expect(student.attendance_record_on_day(student.course.start_date)).to eq nil
      expect(page).to have_css('.label-primary', text: 'Absent')
    end

    scenario "does not change pair" do
      student2 = FactoryBot.create(:student)
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, tardy: true, pair_id: student2.id)
      visit course_day_attendance_records_path(student.course, day: student.course.start_date)
      select "On time", from: student.id.to_s
      wait_for_ajax
      expect(student.attendance_record_on_day(student.course.start_date).pair_id).to eq student2.id
      expect(page).to have_css('.label-success', text: 'On time')
      expect(page).to have_content student2.name
    end
  end
end

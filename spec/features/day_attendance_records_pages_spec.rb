feature 'visiting the day attendance records index page' do
  let(:course) { FactoryBot.create(:course) }
  let(:monday) { Time.zone.now.to_date.beginning_of_week }

  scenario 'as a guest' do
    visit course_day_attendance_records_path(course)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student) }
    before { login_as(student, scope: :student) }

    scenario 'can not visit the page' do
      visit course_day_attendance_records_path(course)
      expect(page).to have_content 'need to sign in'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'can visit the page' do
      visit course_day_attendance_records_path(course)
      expect(page).to have_content 'Attendance for'
    end

    scenario 'can retreive attendance records for a specific day' do
      travel_to monday do
        visit course_day_attendance_records_path(course)
        click_button 'Change day'
        expect(page).to have_content "Attendance for #{monday.strftime("%A %B %d, %Y")}"
      end
    end

    scenario 'shows student name, status, sign in and out times' do
      travel_to monday do
        student_1 = FactoryBot.create(:student, course: course)
        sign_out_time = Time.zone.now.in_time_zone(course.office.time_zone) + 8.hours
        attendance_record = FactoryBot.create(:tardy_attendance_record, date: monday, signed_out_time: sign_out_time, student: student_1)
        visit course_day_attendance_records_path(course, day: monday.to_s)
        expect(page).to have_content student_1.name
        expect(page).to have_content 'Tardy'
        expect(page).to have_content attendance_record.created_at.in_time_zone(course.office.time_zone).strftime('%l:%M %p')
        expect(page).to have_content sign_out_time.strftime('%l:%M %p')
      end
    end

    scenario 'shows pairs' do
      travel_to monday do
        student_1 = FactoryBot.create(:student, course: course)
        student_2 = FactoryBot.create(:student, course: course)
        student_3 = FactoryBot.create(:student, course: course)
        FactoryBot.create(:attendance_record, date: monday, student: student_1, pair_ids: [student_2.id, student_3.id])
        FactoryBot.create(:attendance_record, date: monday, student: student_2, pair_ids: [student_1.id])
        visit course_day_attendance_records_path(course, day: monday.to_s)
        expect(page).to have_css('#pair-name', text: student_2.name)
        expect(page).to have_css('#pair-name', text: student_3.name)
        expect(page).to have_css('.text-danger', text: student_3.name)
        expect(page).to_not have_css('.text-danger', text: student_2.name)
      end
    end
  end
end

def sign_in_as(user, pair=nil)
  visit new_student_session_path
  fill_in 'student_email', with: user.email
  fill_in 'student_password', with: user.password
  if pair
    fill_in 'pair_email', with: pair.email
    fill_in 'pair_password', with: pair.password
    click_button 'Pair sign in'
  else
    click_button 'Student sign in'
  end
end

def create_hello_sign_signature
  click_on 'Got it'
  execute_script('$.fancybox.close()')
  click_on 'I agree'
  find('p', text: 'Click to sign').trigger('click')
  sleep 3
  find('a', text: 'Type it in').trigger('click')
  fill_in 'type-in-text', with: 'Epicodus Student'
  click_on 'Insert'
  execute_script("$('.m-sig-modal').css('display','none')")
  click_on 'I agree'
end

def create_attendance_record_in_course(course, status)
  date = nil
  pair = FactoryBot.create(:student)
  travel_to course.start_date.in_time_zone(course.office.time_zone) + 8.hours do
    existing_attendance_records = AttendanceRecord.where("date between ? and ?", course.start_date, course.end_date)
    date = existing_attendance_records.any? ? existing_attendance_records.order(:date).last.date + 1.day : Time.now
  end
  travel_to date do
    course_attendance_record = FactoryBot.create(:attendance_record, student: course.students.first, pairings_attributes: [pair_id: pair.id])
    course_attendance_record.update(tardy: true) if status == "tardy"
    course_attendance_record.update(left_early: false) if status != "left_early"
  end
end

def get_lead_id(email)
  close_io_client.list_leads('email: "' + email + '"')['data'].each do |lead|
    return lead['id'] if lead['contacts'][0]['emails'][0]['email'] == email
  end
end

def accept_js_alert
  wait = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoSuchAlertError
  alert = wait.until { page.driver.browser.switch_to.alert }
  alert.accept
end
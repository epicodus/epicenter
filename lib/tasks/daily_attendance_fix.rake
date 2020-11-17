# temporary daily task to mark students as on time if daily submission submitted
desc "daily attendance fix"
task :daily_attendance_fix => [:environment] do
  courses = Course.current_courses.non_internship_courses.select { |course| course.class_days.include? Time.zone.now.to_date }
  courses.each do |course|
    course.students.each do |student|
      if student.daily_submissions.where(date: Time.zone.now.to_date).exists? || course.description == '2020-04 React (part-time track)'
        attendance_record = AttendanceRecord.find_or_create_by(student: student, date: Time.zone.now.to_date)
        attendance_record.update(tardy: false, left_early: false)
      end
    end
  end
end

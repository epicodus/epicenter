# temporary daily task to mark students as on time
desc "daily attendance fix"
task :daily_attendance_fix => [:environment] do
  courses = Course.current_courses.non_internship_courses.select { |course| course.class_days.include? Date.today }
  courses.each do |course|
    course.students.each do |student|
      attendance_record = AttendanceRecord.find_or_create_by(student: student, date: Date.today)
      attendance_record.update(tardy: false, left_early: false)
    end
  end
end

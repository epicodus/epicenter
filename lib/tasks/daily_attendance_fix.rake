# temporary daily task to mark students as on time
desc "daily attendance fix"
task :attendance_fix => [:environment] do
  courses = Course.current_courses.where(office_id: 1).or(Course.current_courses.where(office_id: 2))
  courses = courses.select { |course| course.id != 461 } # skip PDX React course
  courses.each do |course|
    course.students.each do |student|
      if course.class_days.include? Date.today
        attendance_record = AttendanceRecord.find_or_create_by(student: student, date: Date.today)
        attendance_record.update(tardy: false, left_early: false)
      end
    end
  end
end

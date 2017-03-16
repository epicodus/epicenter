desc "export students finished level 3 and entering internships"
task :export_graduates, [:day] => [:environment] do |t, args|
  day = args.day || ""
  while day.length != 10
    puts "Enter day in format yyyy-mm-dd:"
    day = STDIN.gets.chomp
  end
  course_ids = Course.where(internship_course: false, parttime: false, office_id: office.id).where('start_date <= ? AND end_date >= ?', day, day).order(:description).map {|course| course.id}
  course_ids.each {|course_id| puts "#{Course.find(course_id).description} (#{Course.find(course_id).office.name})"}
  input = STDIN.gets.chomp.downcase
  if input == "y" || input == "yes"
    course_ids.each do |course_id|
      course = Course.find(course_id)
      course.students.each do |student|
        attendance_record = student.attendance_record_on_day(day)
        if update_absent_students && !attendance_record
          attendance_record = AttendanceRecord.create(student: student, date: Time.parse(day).to_date)
        end
        if attendance_record
          if tardy && leftearly
            attendance_record.update(tardy: false, left_early: false)
          elsif tardy
            attendance_record.update(tardy: false)
          elsif leftearly
            attendance_record.update(left_early: false)
          end
        end
      end
      puts "Successfully updated attendance records for #{course.id} - #{course.description} (#{course.office.name})"
    end
  end
end

# interactive rake task to mark students as on time
# usage: rake update_attendance or rake "update_attendance[yyyy-mm-dd]"
desc "update attendance"
task :update_attendance, [:day] => [:environment] do |t, args|
  day = args.day || ""
  while day.length != 10
    puts "Enter day in format yyyy-mm-dd:"
    day = STDIN.gets.chomp
  end
  puts "Update absent students too? (y/N)"
  update_absent_students = STDIN.gets.chomp.downcase == "y"
  puts "Update ALL courses for an office? (y/N)"
  input = STDIN.gets.chomp.downcase
  if input == "y" || input == "yes"
    puts "Enter office name or id:"
    input = STDIN.gets.chomp
    office = Office.find_by(name: input) || Office.find(input)
    course_ids = Course.current_courses.where(internship_course: false, office_id: office.id).map {|course| course.id}
  else
    puts "Enter course id:"
    course_ids = [Course.find(STDIN.gets.chomp)]
  end
  modifier = update_absent_students ? "including" : "excluding"
  puts "Update attendance records for the following courses on #{day} (*#{modifier}* absent students)? (y/N)"
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
        attendance_record.update(tardy: false, left_early: false) if attendance_record
      end
      puts "Successfully updated attendance records for #{course.id} - #{course.description} (#{course.office.name})"
    end
  else
    puts "Task canceled!"
  end
end

  #   end
  # else
  #   puts 'To mark as on time only tardy / left_early students: rake "update_attendance[yyyy-mm-dd, course_id, false]"'
  #   puts 'To mark as on time *all* students, including those absent: rake "update_attendance[yyyy-mm-dd, course_id, true]"'
  # end

# interactive rake task to mark students as on time
# usage: rake update_attendance or rake "update_attendance[yyyy-mm-dd]"
desc "update attendance"
task :update_attendance, [:day] => [:environment] do |t, args|
  day = args.day || ""
  while day.length != 10
    puts "Enter day in format yyyy-mm-dd:"
    day = STDIN.gets.chomp
  end
  puts "Fix tardy, left early, or both? (t/l/B)"
  input = STDIN.gets.chomp.downcase[0]
  tardy = input != 'l'
  leftearly = input != 't'
  if tardy && leftearly
    puts "Update absent students too? (y/N)"
    update_absent_students = STDIN.gets.chomp.downcase == "y"
  else
    update_absent_students = false
  end
  puts "Update ALL day-time courses for an office? (y/N)"
  input = STDIN.gets.chomp.downcase[0]
  if input == "y"
    puts "Enter office name or id:"
    input = STDIN.gets.chomp
    office = Office.find_by(name: input) || Office.find(input)
    course_ids = Course.where(internship_course: false, parttime: false, office_id: office.id).where('start_date <= ? AND end_date >= ?', day, day).order(:description).map {|course| course.id}
  else
    puts "Enter course id:"
    course_ids = [Course.find(STDIN.gets.chomp)]
  end
  modifier = update_absent_students ? "INCLUDING" : "EXCLUDING"
  if tardy && leftearly
    puts "Set all attendance records to ON TIME for the following courses on #{day} (#{modifier} absent students)? (y/N)"
  elsif tardy
    puts "Change only TARDY attendance records for the following courses on #{day}? (y/N)"
  elsif leftearly
    puts "Change only LEFT_EARLY attendance records for the following courses on #{day}? (y/N)"
  end
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
  else
    puts "Task canceled. No records updated."
  end
end

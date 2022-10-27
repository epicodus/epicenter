desc "send attendance warnings"
task :send_warnings => [:environment] do
  Course.current_courses.non_internship_courses.each do |course|
    if course.number_of_days_since_start == 1
      p "first day of course - reset attendance sent counter for all students in #{course.description}"
      course.students.update_all(attendance_warnings_sent: nil)
    else
      course.students.each do |student|
        if student.crm_lead.status == 'Enrolled'
          # set friday attendance to on time automatically
          if Date.today.friday? && course.class_days.include?(Date.today)
            attendance_record = AttendanceRecord.find_or_initialize_by(student: student, date: Date.today)
            attendance_record.tardy = false
            attendance_record.left_early = false
            attendance_record.save
          end

          # send attendance warnings (all courses)
          if student.attendance_warnings_sent == 1 && student.absences(course) >= 4
            if Rails.env.production?
              Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
                { :from => "no-reply@epicodus.com",
                  :to => "#{course.admin.email}",
                  :subject => "#{student.name} has #{student.absences(course)} absences",
                  :text => "Notification to teacher: #{student.name} has #{student.absences(course)} absences this unit." })
            else
              p "#{student.name} absent #{student.absences(course)} days. Email teacher."
            end
            student.update(attendance_warnings_sent: 2)
          elsif !student.attendance_warnings_sent && student.absences(course) >= 2.5
            if Rails.env.production?
              Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
                { :from => "no-reply@epicodus.com",
                  :to => "#{student.name} <#{student.email}>",
                  :cc => course.admin.email,
                  :subject => "Missing class - #{student.name}",
                  :text => "This is an automated message. As of today, you've missed #{student.absences(course)} class days in your current course.  As a reminder, we have a strict attendance policy that allows for a specific number of missed days of class depending on whether you are a full-time or part-time student. If you miss more days than what our attendance policy allows, you will be expelled. Please review the attendance section of the student handbook for the details.",
                  :html => "<p>This is an automated message. As of today, you've missed #{student.absences(course)} in your current course.</p><p>As a reminder, we have a strict attendance policy that allows for a specific number of missed days of class depending on whether you are a full-time or part-time student. If you miss more days than what our attendance policy allows, you will be expelled. Please review the attendance section of the <a href='https://www.learnhowtoprogram.com/introduction-to-programming/getting-started-at-epicodus/student-handbook'>student handbook</a> for the details.</p>" })
            else
              p "#{student.name} absent #{student.absences(course)} days. Email student & teacher."
            end
            student.update(attendance_warnings_sent: 1)
          end
        end
      end
    end
  end
end

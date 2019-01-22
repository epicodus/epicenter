desc "send attendance and solo warnings"
task :send_warnings => [:environment] do
  Course.current_courses.non_internship_courses.each do |course|
    if course.number_of_days_since_start == 1
      p "first day of course - reset attendance & solo warnings sent counters for all students in #{course.description}"
      course.students.update_all(attendance_warnings_sent: nil)
      course.students.update_all(solo_warnings_sent: nil)
    else
      course.students.each do |student|

        # set friday attendance to on time automatically for fulltime classes (except week 1 of intro)
        if Date.today.friday? && (course.language.level > 0 || course.number_of_days_since_start > 5) && !course.parttime?
          attendance_record = AttendanceRecord.find_or_initialize_by(student: student, date: Date.today)
          attendance_record.tardy = false
          attendance_record.left_early = false
          attendance_record.save
        end

        # send attendance warnings (fulltime and parttime)
        if student.attendance_warnings_sent == 1 && student.absences(course) >= 4
          if Rails.env.production?
            Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "it@epicodus.com",
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
              { :from => "#{course.teacher} <#{course.admin.email}>",
                :to => "#{student.name} <#{student.email}>",
                :bcc => course.admin.email,
                :subject => "Missing class - #{student.name}",
                :text => "This is an automated message. As of today, you've missed #{student.absences(course)} class days. We've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in. As a reminder, if you miss more than 20% of a course (typically 5 days), you may be asked to leave the program. If you have any questions or concerns about attendance, please reach out to your teacher. Your teacher may also schedule a meeting with you to check in.",
                :html => "<p>This is an automated message. As of today, you've missed #{student.absences(course)} class days.</p><p>We've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in.</p><p>As a reminder, if you miss more than 20% of a course (typically 5 days), you may be asked to leave the program. If you have any questions or concerns about attendance, please reach out to your teacher. Your teacher may also schedule a meeting with you to check in.</p>" })
          else
            p "#{student.name} absent #{student.absences(course)} days. Email student & teacher."
          end
          student.update(attendance_warnings_sent: 1)
        end

        # send solo warnings (fulltime courses only)
        if !student.solo_warnings_sent && student.solos(course) >= 2 && !course.parttime?
          if Rails.env.production?
            Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "it@epicodus.com",
                :to => "#{course.admin.email}",
                :subject => "#{student.name} has #{student.solos(course)} solos",
                :text => "Notification to teacher: #{student.name} has #{student.solos(course)} solos this unit. The student has NOT been notified." })
          else
            p "#{student.name} has #{student.solos(course)} SOLOS. Email teacher."
          end
          student.update(solo_warnings_sent: 1)
        end

      end
    end
  end
end

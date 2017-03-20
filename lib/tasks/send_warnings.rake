desc "send attendance and solo warnings"
task :send_warnings => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.each do |course|
    if course.number_of_days_since_start == 1
      p "first day of course - reset attendance & solo warnings sent counters for all students in #{course.description}"
      course.students.update_all(attendance_warnings_sent: nil)
      course.students.update_all(solo_warnings_sent: nil)
    else
      course.students.each do |student|

        # send attendance warnings
        if student.attendance_warnings_sent == 1 && student.absences(course) >= 4
          if Rails.env.production?
            Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "it@epicodus.com",
                :to => "#{course.admin.email}",
                :cc => "debbie@epicodus.com",
                :subject => "#{student.name} has #{student.absences(course)} absences",
                :text => "Notification to teacher: #{student.name} has #{student.absences(course)} absences this unit." })
          else
            p "#{student.name} absent #{student.absences(course)} days. Email teacher & Debbie."
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

        # send solo warnings
        if student.solo_warnings_sent == 1 && student.solos(course) >= 3
          if Rails.env.production?
            Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "it@epicodus.com",
                :to => "#{course.admin.email}",
                :cc => "debbie@epicodus.com",
                :subject => "#{student.name} has #{student.solos(course)} solos",
                :text => "Notification to teacher: #{student.name} has #{student.solos(course)} solos this unit." })
          else
            p "#{student.name} has #{student.solos(course)} SOLOS. Email teacher & Debbie."
          end
          student.update(solo_warnings_sent: 2)
        elsif !student.solo_warnings_sent && student.solos(course) >= 2
          if Rails.env.production?
            Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "#{course.teacher} <#{course.admin.email}>",
                :to => "#{student.name} <#{student.email}>",
                :bcc => course.admin.email,
                :subject => "Pairing - #{student.name}",
                :text => "This is an automated message. As of today, you’ve worked solo for #{student.solos(course)} days. Pairing is a fundamental and required part of the Epicodus experience and pedagogy. While pairing can be challenging, students that pair consistently do better in our classes than those that don't. When students don't pair, it has a negative impact on our classroom culture. Please make sure you pair with classmates every day. If you continue to solo, you may be asked to leave the program. Our model has been successful for many students, but it's not for everyone so think about it and understand that we take pair programming very seriously. If you have any issues or concerns about finishing your track using the pair programming method, please check in with your teacher. Your teacher may also schedule a meeting with you to check in.",
                :html => "<p>This is an automated message. As of today, you’ve worked solo for #{student.solos(course)} days.</p><p>Pairing is a fundamental and required part of the Epicodus experience and pedagogy. While pairing can be challenging, students that pair consistently do better in our classes than those that don't. When students don't pair, it has a negative impact on our classroom culture.</p><p>Please make sure you pair with classmates every day. If you continue to solo, you may be asked to leave the program. Our model has been successful for many students, but it's not for everyone so think about it and understand that we take pair programming very seriously.</p><p>If you have any issues or concerns about finishing your track using the pair programming method, please check in with your teacher. Your teacher may also schedule a meeting with you to check in.</p>" })
          else
            p "#{student.name} has #{student.solos(course)} SOLOS. Email student & teacher."
          end
          student.update(solo_warnings_sent: 1)
        end

      end
    end
  end
end

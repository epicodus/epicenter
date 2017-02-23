desc "send attendance and solo warnings"
task :send_warnings => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.each do |course|
    if course.number_of_days_since_start == 1
      p "first day of course - reset attendance & solo warnings sent counters for all students in #{course.description}"
      course.students.update_all(attendance_warnings_sent: nil)
      course.students.update_all(solo_warnings_sent: nil)
    elsif course.number_of_days_since_start > 5
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
                :subject => "Missing class",
                :text => "Hi #{student.name}. As of today, you've missed #{student.absences(course)} class days. While we're reluctant to second-guess our students' choices and needs around their schedules, we've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in. As a reminder, here's Epicodus's attendance policy: If you miss 10% of a course (typically 2.5 days), a teacher will talk to you about your attendance, remind you of this policy, and send you an email. You will be expelled if you miss more than 20% of a course (typically 5 days). Please let me know if there's anything I can do to help you out or support you better in your studies here.",
                :html => "<p>Hi #{student.name}. As of today, you've missed #{student.absences(course)} class days. While we're reluctant to second-guess our students' choices and needs around their schedules, we've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in.</p><p>As a reminder, here's Epicodus's attendance policy:</p><p>If you miss 10% of a course (typically 2.5 days), a teacher will talk to you about your attendance, remind you of this policy, and send you an email. You will be expelled if you miss more than 20% of a course (typically 5 days).</p><p>Please let me know if there's anything I can do to help you out or support you better in your studies here.</p>" })
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
                :subject => "Pairing",
                :text => "INSERT PLAINTEXT VERSION OF SOLO WARNING HERE",
                :html => "INSERT HTML VERSION OF SOLO WARNING HERE" })
          else
            p "#{student.name} has #{student.solos(course)} SOLOS. Email student & teacher."
          end
          student.update(solo_warnings_sent: 1)
        end
      end
    end
  end
end

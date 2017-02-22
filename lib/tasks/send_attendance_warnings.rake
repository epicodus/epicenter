desc "send attendance warnings"
task :send_attendance_warnings => [:environment] do
  Student.where(attendance_warning_sent: nil).each do |student|
    if student.class_in_session? && !student.course.internship_course? && !student.course.parttime? && student.course.number_of_days_since_start > 5
      if student.absences(student.course) >= 2.5
        Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
          "epicodus.com",
          { :from => "#{student.course.teacher} <#{student.course.admin.email}>",
            :to => "#{student.name} <#{student.email}>",
            :bcc => student.course.admin.email,
            :subject => "Missing class",
            :text => "Hi #{student.name}. As of today, you've missed #{student.absences(student.course)} class days. While we're reluctant to second-guess our students' choices and needs around their schedules, we've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in. As a reminder, here's Epicodus's attendance policy: If you miss 10% of a course (typically 2.5 days), a teacher will talk to you about your attendance, remind you of this policy, and send you an email. You will be expelled if you miss more than 20% of a course (typically 5 days). Please let me know if there's anything I can do to help you out or support you better in your studies here.",
            :html => "<p>Hi #{student.name}. As of today, you've missed #{student.absences(student.course)} class days. While we're reluctant to second-guess our students' choices and needs around their schedules, we've found that our students do much better in class when they come every day to work with their peers and get support from our teachers, and that the structure and accountability of an attendance policy helps many people prioritize coming in.</p><p>As a reminder, here's Epicodus's attendance policy:</p><p>If you miss 10% of a course (typically 2.5 days), a teacher will talk to you about your attendance, remind you of this policy, and send you an email. You will be expelled if you miss more than 20% of a course (typically 5 days).</p><p>Please let me know if there's anything I can do to help you out or support you better in your studies here.</p>" }
        )
        student.update(attendance_warning_sent: true)
      end
    end
  end
end

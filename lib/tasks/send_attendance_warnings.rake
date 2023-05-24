desc "send attendance warnings"
task :send_attendance_warnings => [:environment] do
  courses = Course.current_courses.non_internship_courses.where.not(track_id: nil)
  students = Student.where(id: courses.map {|c| c.students}.flatten)
  students.each do |student|
    begin
      unless student.email.include?('example.com') || student.email.include?('epicodus.com')
        if student.crm_lead.status == 'Enrolled'
          if student.is_classroom_day?
            email_triggers = student.course.parttime? ? [4, 10, 15] : [2, 5, 8] # PT is intro & full-stack
            absences = student.absences_cohort.floor # rounded down so triggers not skipped
            if email_triggers.include?(absences) && !already_sent?(student, absences)
              if Rails.env.production?
                WebhookAttendanceWarnings.new(name: student.name, student: student.email, teacher: student.course.admin.email, absences: student.absences_cohort, allowed_absences: student.allowed_absences)
              else
                puts "#{student.course.parttime? ? 'PT' : 'FT'} #{student.name} absent #{student.absences_cohort} out of #{student.allowed_absences} allowed absences."
              end
              student.update(attendance_warnings_sent: absences)
            end
          elsif student.is_class_day?
            create_attendance_record_for(student)
          end
        end
      end
    rescue => e
      puts "Error sending attendance warning for student #{student.email}: #{e}"
      Bugsnag.notify(e)
    end
  end
end

def create_attendance_record_for(student)
  attendance_record = AttendanceRecord.find_or_initialize_by(student: student, date: Time.zone.now.to_date)
  attendance_record.tardy = false
  attendance_record.left_early = false
  attendance_record.save
end

def already_sent?(student, absences)
  student.attendance_warnings_sent == absences
end
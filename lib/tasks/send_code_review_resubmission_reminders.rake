desc "send previous week code review resubmission reminders - run this script 10am Sundays"
task :send_code_review_resubmission_reminders => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.each do |course|
    local_date = Time.now.in_time_zone(course.office.time_zone).to_date
    if local_date.sunday?
      code_review = course.code_reviews.find_by(due_date: local_date - 9.days)
      if code_review
        course.students.each do |student|
          unless code_review.expectations_met_by?(student) || code_review.submission_for(student).try(:needs_review?)
            if Rails.env.production?
              Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "no-reply@epicodus.com",
                :to => "#{student.name} <#{student.email}>",
                :cc => course.admin.email,
                :subject => "Resubmission missing for Independent Project #{course.description} Week #{code_review.number} - #{student.name}",
                :text => "This is an automated message. According to our records, you have not yet resubmitted your project from week #{code_review.number} for #{course.description}, which was reviewed and evaluated as failing one or more objectives. We strongly encourage all students to complete resubmissions promptly, so that you do not fall behind, and to give your teacher time to review your work and provide you with valuable feedback.  Please make arrangements to rework your failing project and submit it as soon as possible. If you do not submit work that clearly demonstrates an effort to pass before #{(local_date + 1.day).strftime('%A %B %d')}, you may be withdrawn from class. Your teacher has received a copy of this email." })
            else
              p "Resubmission missing for Independent Project #{course.description} Week #{code_review.number} - #{student.name}"
            end
          end
        end
      end
    end
  end
end

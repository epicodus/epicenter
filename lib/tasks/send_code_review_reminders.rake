desc "send code review submission reminders - run this script after 5pm Fridays"
task :send_code_review_reminders => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.each do |course|
    local_date = Time.now.in_time_zone(course.office.time_zone).to_date
    if local_date.friday?
      code_review = course.code_reviews.find_by(date: local_date)
      if code_review
        course.students.each do |student|
          if code_review.submission_for(student).nil?
            if Rails.env.production?
              Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
              { :from => "#{course.teacher} <#{course.admin.email}>",
                :to => "#{student.name} <#{student.email}>",
                :bcc => course.admin.email,
                :subject => "Friday project for week #{code_review.number} of #{course.description} not yet submitted - #{student.name}",
                :text => "This is an automated message. According to our records, we have not yet received a submission for your Friday work. Please remember to submit your work as soon as you complete it. Your teacher has received a copy of this email." })
            else
              p "Friday project for week #{code_review.number} of #{course.description} not yet submitted - #{student.name}"
            end
          end
        end
      end
    end
  end
end

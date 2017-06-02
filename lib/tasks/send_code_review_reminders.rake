desc "send code review submission reminders - run this script after 5pm Fridays"
task :send_code_review_reminders => [:environment] do
  Course.current_courses.fulltime_courses.non_internship_courses.each do |course|
    course.students.each do |student|
      code_review = course.code_reviews.find_by(date: Time.zone.now.to_date)
      if Date.today.friday? && code_review && code_review.submission_for(student).nil?
        if Rails.env.production?
          Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
          { :from => "#{course.teacher} <#{course.admin.email}>",
            :to => "#{student.name} <#{student.email}>",
            :bcc => course.admin.email,
            :subject => "Friday project for week #{code_review.number} of #{course.description} not yet submitted - #{student.name}.",
            :text => "This is an automated message. According to our records, we have not yet received a submission for your Friday work. Please remember to submit your work as soon as you complete it. Your teacher has received a copy of this email." })
        else
          p "#{student.name} in #{course.description} has not yet submitted code review."
        end
      end
    end
  end
end

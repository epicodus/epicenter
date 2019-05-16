desc "warn teachers when not passing code review 17 days after due date"
task :warn_teachers_late_code_reviews => [:environment] do
  due_date = Date.today - 17.days
  CodeReview.where(date: due_date).each do |code_review|
    course = code_review.course
    course.students.each do |student|
      unless student.submission_for(code_review).try(:review_status) == 'pass'
        if Rails.env.production?
          Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message("epicodus.com",
            { :from => "it@epicodus.com",
              :to => "#{course.teacher} <#{course.admin.email}>",
              :subject => "#{student.name} not passing #{code_review.title}",
              :text => "#{student.name} not passing #{code_review.title} (#{course.description} #{student.office.short_name}) after 17 days." })
        else
          p "#{student.name} not passing #{code_review.title} (#{course.description} #{student.office.short_name}) after 17 days."
        end
      end
    end
  end
end

desc "email teachers names of students with no checkins this week"
task :report_checkins => [:environment] do
  if Date.today.saturday?
    recipients = ''
    filename = File.join(Rails.root.join('tmp'), 'no-checkins.txt')
    File.open(filename, 'w') do |file|
      current_courses = Course.current_courses.non_internship_courses.non_fidgetech_courses
      recently_ended_courses = Course.non_internship_courses.where('end_date > ?', Date.today-6.days).where('end_date < ?', Date.today)
      courses = current_courses + recently_ended_courses
      file.puts 'No check-ins this week:'
      file.puts ''
      courses.each do |course|
        students = course.students.reject { |student| student.checkins.week(Date.today - 1.day).count > 0 }
        if students.any?
          file.puts course.description
          file.puts students.map(&:name).sort.join(', ')
          file.puts ''
        end
      end
      students = Student.where(id: courses.map(&:students).flatten.map(&:id))
      recipients = courses.map(&:admin).map(&:email).uniq.join(', ').concat(', teacher-lead@epicodus.com')
    end

    if Rails.env.production?
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      message_params =  { from: 'it@epicodus.com',
                          to: recipients,
                          subject: "Check-in report for week ending #{Date.today.strftime('%m/%d/%Y')}",
                          text: 'Students with no check-ins this week',
                          attachment: File.new(filename)
                        }
      result = mg_client.send_message('epicodus.com', message_params)
      puts result.body.to_s
    end
  end
end

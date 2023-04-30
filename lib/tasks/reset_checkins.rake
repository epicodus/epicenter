desc "reset checkins and email teachers names of students with no checkins this week"
task :reset_checkins => [:environment] do
  if Date.today.saturday?

    recipients = ''
    filename = File.join(Rails.root.join('tmp'), 'no-checkins.txt')
    File.open(filename, 'w') do |file|
      courses = Course.current_courses.non_internship_courses.where.not(description: 'Fidgetech')
      file.puts 'No check-ins this week:'
      file.puts ''
      courses.each do |course|
        students = course.students.where(checkins: 0)
        if students.any?
          file.puts course.description
          file.puts students.pluck(:name).sort.join(', ')
          file.puts ''
        end
      end
      students = Student.where(id: courses.map(&:students).flatten.map(&:id))
      students.update_all(checkins: 0)
      recipients = courses.map(&:admin).map(&:email).uniq.join(', ')
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
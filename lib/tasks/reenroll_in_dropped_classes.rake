desc "add location descriptor to all stripe payments"
task :reenroll_in_dropped_classes => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'enrolled.txt')
  File.open(filename, 'w') do |file|
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)

    Student.all.order(:created_at).each do |student|
      if student.payments.count > 0 && student.courses.count == 0 # no courses listed
        lead = close_io_client.list_leads('email:' + student.email)
        begin
          close_io_class = lead.data.first.custom.Class
          if close_io_class
            course = Course.find_by(description: close_io_class)
            if !course
              case close_io_class
              when "2015-09 Evening"
                course = Course.find_by(description: "2015-09 Intro (Evening)")
              when "2016-01 Evening"
                course = Course.find_by(description: "2016-01 Intro - Evening")
              when "2016-04 Evening"
                course = Course.find_by(description: "2016-04 Intro - Evening")
              when "2016-06 Intro SEATTLE"
                course = Course.find_by(description: "2016-06 Intro")
              when "2016-08 Evening"
                course = Course.find_by(description: "2016-08 Intro - Evening")
              when "2016-08 Intro PHILLY"
                course = Course.find(62)
              when "2016-08 Intro SEATTLE"
                course = Course.find(73)
              end
            end
            description = "#{student.id}; #{student.name}; #{course.description}"
            student.courses.push(course)
            Enrollment.find_by(student: student, course: course).destroy
            file.puts(description)
          end
        rescue NoMethodError => error
          file.puts("#{student.id}; #{student.name}; INCORRECT EMAIL")
        end
      end
    end
  end
  puts "Exported to #{filename.to_s}"
end

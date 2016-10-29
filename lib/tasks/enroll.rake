require 'csv'
require 'net/http'

desc "enroll students in courses based on csv"
task :enroll_students => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'enrollments.txt')
  File.open(filename, 'w') do |file|
    # csv_text = File.read('enrollment_import.csv') # for local testing
    uri = URI('http://mortalwombat.net/tmp/enrollment_import.csv')
    csv_text = Net::HTTP.get(uri)
    csv = CSV.parse(csv_text)
    csv.each do |row|
      student = User.find_by(name: row[0])
      if student
        row.each do |column|
          begin
            if column && column.include?('@epicodus.com')
              course = Course.find_by(description: column.split('_')[0], admin: Admin.find_by(email: column.split('_')[1]))
              enrollment = Enrollment.new(student_id: student.id, course_id: course.id)
              if enrollment.save
                file.puts "enrollment successful: #{student.name} in #{course.description}"
              else
                file.puts "FAILURE TO ENROLL: Enrollment not made for #{student.name} in #{course.description}"
              end
            end
          rescue
            file.puts "UNEXPECTED ERROR: #{student.name}"
          end
        end
      else
        file.puts "STUDENT NOT FOUND: #{row[0]}"
      end
    end
  end

  begin
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("mike@epicodus.com", {"first"=>"Mike", "last" => "Goren"});
    mb_obj.add_recipient(:to, "mike@epicodus.com", {"first" => "Mike", "last" => "Goren"});
    mb_obj.set_subject("enrollments.txt");
    mb_obj.set_text_body("enrollments.txt should be attached");
    mb_obj.add_attachment(filename, "enrollments.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  rescue
    puts "Unable to send file. Saved as #{filename.to_s}"
  end

end

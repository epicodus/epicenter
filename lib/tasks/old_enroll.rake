require 'csv'
require 'net/http'

desc "enroll students in courses based on csv"
task :enroll_students => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'enrollments.txt')
  File.open(filename, 'w') do |file|
    if Rails.env.production?
      uri = URI('http://mortalwombat.net/tmp/enrollment_import.tsv')
      csv_text = Net::HTTP.get(uri)
      csv = CSV.parse(csv_text, { :col_sep => "\t" })
    else
      csv = CSV.read("enrollment_import.tsv", { :col_sep => "\t" }) # for local testing
    end
    csv.each do |row|
      student = User.find_by(email: row[0])
      if student
        row.each do |column|
          begin
            if column && column.include?('@epicodus.com')
              course = Course.find_by(description: column.split('_')[0], admin: Admin.find_by(email: column.split('_')[1]))
              enrollment = Enrollment.new(student_id: student.id, course_id: course.id)
              if enrollment.save
                file.puts "enrollment successful: #{student.name} in #{course.description}"
              else
                file.puts "ERROR - FAILURE TO ENROLL: Enrollment not made for #{student.name} in #{course.description}"
              end
            end
          rescue
            file.puts "ERROR - UNEXPECTED ERROR: #{student.name}"
          end
        end
      else
        file.puts "ERROR - STUDENT NOT FOUND: #{row[0]}"
      end
    end
  end
  if Rails.env.production?
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
  else
    puts "Saved as #{filename.to_s}"
  end
end

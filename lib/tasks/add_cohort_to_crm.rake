# calculates cohort as graduation date (yyyy-mm) combined with name of level 3 language taken just beforehand
desc "retroactively add cohort to crm based on graduation date"
task :add_cohort_to_crm, [:day] => [:environment] do |t, args|
  day = args.day || ""
  while day.length != 10
    puts "Enter graduation date in format yyyy-mm-dd:"
    day = STDIN.gets.chomp
  end
  internship_courses = Course.internship_courses.where('end_date = ?', day)
  puts "Export graduates for a specific office? (y/N)"
  input = STDIN.gets.chomp.downcase[0]
  if input == "y"
    puts "Enter office name or id:"
    input = STDIN.gets.chomp
    office = Office.find_by(name: input) || Office.find(input)
    internship_courses = internship_courses.where(office: office)
  end
  filename = File.join(Rails.root.join('tmp'), 'graduates.txt')
  File.open(filename, 'w') do |file|
    internship_courses.each do |internship_course|
      previous_courses = Course.courses_for(internship_course.office).where('end_date > ? AND end_date < ?', internship_course.start_date - 3.weeks, internship_course.start_date).select {|course| course.language && course.language.level == 3 }
      previous_courses.each do |course|
        course.students.each do |student|
          if internship_course.students.exists?(student)
            if student.close_io_lead_exists?
              student.update_close_io({ 'custom.Cohort': day[0..6] + " " + course.language.name })
              file.puts "UPDATED: #{student.name}, #{student.email}, #{day[0..6] + " " + course.language.name}"
            else
              file.puts "NOT FOUND: #{student.name}, #{student.email}"
            end
          end
        end
      end
    end
  end
  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("mike@epicodus.com", {"first"=>"Mike", "last" => "Goren"});
    mb_obj.add_recipient(:to, "mike@epicodus.com", {"first" => "Mike", "last" => "Goren"});
    mb_obj.set_subject("graduates.txt");
    mb_obj.set_text_body("rake task: export_graduates");
    mb_obj.add_attachment(filename, "graduates.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

desc "update part-time students lead status on last day of class - run this script after 9pm"
task :mark_part_time_graduates => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'updated_part_time_graduates.txt')
  counter = 0
  File.open(filename, 'w') do |file|
    Course.parttime_courses.current_courses.each do |course|
      local_date = Time.now.in_time_zone(course.office.time_zone).to_date
      if course.end_date == local_date
        course.students.each do |student|
          student.crm_lead.update({ status: "Part-Time Graduate" }) if student.crm_lead.status == "Enrolled - Part-Time"
          file.puts "Updated lead status for #{course.description} (#{course.office.name}): #{student.email}"
          counter += 1
        end
      end
    end
  end

  if Rails.env.production? && counter > 0
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: mark_part_time_graduates");
    mb_obj.set_text_body("rake task: mark_part_time_graduates");
    mb_obj.add_attachment(filename, "updated_part_time_graduates.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "No part-time graduates today."
  end
end

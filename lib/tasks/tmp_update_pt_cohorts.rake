desc "update cohorts in Epicenter (which should update them in Close)"
task :tmp_update_pt_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_pt_cohorts.txt')
  IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  File.open(filename, 'w') do |file|
    parttime_students = Student.select {|s| s.courses.parttime_courses.any? && s.courses.parttime_courses.first.start_date > Date.parse('2017-01-01')}
    parttime_students.each do |student|
      unless IGNORE_LIST.include? student.email
        student.parttime_cohort = student.calculate_parttime_cohort
        student.starting_cohort = student.calculate_starting_cohort
        student.cohort = student.calculate_current_cohort
        if student.changed?
          student.save
          file.puts student.email
        end
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Leads missing cohorts");
    mb_obj.set_text_body("rake task: tmp_update_pt_cohorts");
    mb_obj.add_attachment(filename, "tmp_update_pt_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

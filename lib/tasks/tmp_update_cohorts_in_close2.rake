# NOTE BEFORE USE: CLEAR EXISTING STARTING & ENDING COHORT FIELDS FROM CLOSE FIRST
# retroactively add starting and ending cohort to students in Epicenter & Close (where cohort exists)
desc "add new cohort names to Close"
task :tmp_update_cohorts_in_close2 => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_cohorts_in_close2.txt')
  File.open(filename, 'w') do |file|
    Student.all.each do |student|
      if student.cohort || student.starting_cohort
        file.puts "#{student.starting_cohort.try(:description)} | #{student.cohort.try(:description)} | #{student.email}"
        student.crm_lead.update({ 'custom.Cohort - Starting': student.starting_cohort.try(:description), 'custom.Cohort - Current': student.cohort.try(:description) })
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_update_cohorts_in_close2");
    mb_obj.set_text_body("rake task: tmp_update_cohorts_in_close2");
    mb_obj.add_attachment(filename, "tmp_update_cohorts_in_close2.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

desc "find leads in Close missing starting cohort"
task :find_leads_missing_cohorts_2 => [:environment] do
  counter = 0
  filename = File.join(Rails.root.join('tmp'), 'find_leads_missing_cohorts_2.txt')
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  leads = close_io_client.list_leads('email: *', 5000)[:data]
  File.open(filename, 'w') do |file|
    leads.each do |lead|
      email = lead['contacts'].first['emails'].first['email']
      student = Student.with_deleted.find_by(email: email)
      if student
        starting_cohort_crm = lead.try('dig', 'custom').try('dig', Rails.application.config.x.crm_fields['COHORT_STARTING'])
        current_cohort_crm = lead.try('dig', 'custom').try('dig', Rails.application.config.x.crm_fields['COHORT_CURRENT'])
        starting_cohort_epicenter = student.starting_cohort.try(:description)
        current_cohort_epicenter = student.cohort.try(:description)
        if starting_cohort_crm.try(:include?, '2018') || starting_cohort_crm.try(:include?, '2019') || current_cohort_crm.try(:include?, '2018') || current_cohort_crm.try(:include?, '2019')
          if starting_cohort_crm != starting_cohort_epicenter || current_cohort_crm != current_cohort_epicenter
            counter += 1
            file.puts email
            file.puts "Starting Cohort CRM: #{starting_cohort_crm}"
            file.puts "Starting Cohort Epicenter: #{starting_cohort_epicenter}"
            file.puts "Current Cohort CRM: #{current_cohort_crm}"
            file.puts "Current Cohort Epicenter: #{current_cohort_epicenter}"
            file.puts ""
          end
        end
      end
    end
  end #File.open

  if Rails.env.production? && counter > 0
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Leads missing cohorts");
    mb_obj.set_text_body("rake task: find_leads_missing_cohorts_2");
    mb_obj.add_attachment(filename, "find_leads_missing_cohorts_2.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "Looks good! All starting and current cohorts in Epicenter & Close are as expected."
  end
end

desc "find duplicate leads in Close"
task :find_duplicate_leads => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'duplicate_or_missing_leads.txt')
  File.open(filename, 'w') do |file|
    Student.all.each do |student|
      if !student.close_io_lead_exists?
        file.puts("#{student.name} - #{student.email}")
      end
    end
  end
  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Duplicate or missing Close leads");
    mb_obj.set_text_body("rake task: find_duplicate_leads");
    mb_obj.add_attachment(filename, "duplicate_or_missing_leads.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

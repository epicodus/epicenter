desc "find duplicate leads in Close"
task :find_duplicate_leads => [:environment] do
  IGNORE_LIST = ["do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'duplicate_or_missing_leads.txt')
  counter = 0
  File.open(filename, 'w') do |file|
    Student.all.each do |student|
      unless IGNORE_LIST.include? student.email
        lead = close_io_client.list_leads('email:' + student.email)
        if lead['total_results'] == 0
          file.puts("NOT FOUND: #{student.email}")
          counter += 1
        elsif lead['total_results'] > 1
          file.puts("DUPLICATES FOUND: #{student.email}") if lead['total_results'] > 1
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
    mb_obj.set_subject("Duplicate or missing Close leads");
    mb_obj.set_text_body("rake task: find_duplicate_leads");
    mb_obj.add_attachment(filename, "duplicate_or_missing_leads.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "No missing or duplicate leads found! :)"
  end
end

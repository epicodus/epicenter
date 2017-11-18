desc "seed Cohort Applied field based on What Class Are You Interested In field"
task :tmp_migrate_old_address_field => [:environment] do
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'tmp_migrate_old_address_field.txt')
  File.open(filename, 'w') do |file|
    close_io_client.list_leads('"custom.Where do you currently live?":*', 5000)[:data].each do |lead|
      begin
        email = lead['contacts'].first['emails'].first.try(:email)
        new_address = lead.custom['Where do you currently live?']
        existing_addresses = lead.addresses
        old_count = existing_addresses.count
        updated_addresses = existing_addresses.push(Hashie::Mash.new({ label: "other", address_1: new_address }))
        new_count = updated_addresses.count
        file.puts "#{old_count}->#{new_count} | #{email} | #{new_address}"
        close_io_client.update_lead(lead.id, { addresses: updated_addresses })
      rescue
        file.puts "ERROR: #{email} | lead.try(:id)"
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_migrate_old_address_field");
    mb_obj.set_text_body("rake task: tmp_migrate_old_address_field");
    mb_obj.add_attachment(filename, "tmp_migrate_old_address_field.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

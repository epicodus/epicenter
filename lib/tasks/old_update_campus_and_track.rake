desc "update campus and track fields in Close based on what class are you interested in field"
task :update_campus_and_track => [:environment] do
  counter = 0
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'updated_campus_and_track.txt')
  File.open(filename, 'w') do |file|
    close_io_client.list_leads('"custom.What class are you interested in?":track', 5000)[:data].each do |lead|
      what_class_are_you_interested_in = lead.custom['What class are you interested in?']
      new_campus = what_class_are_you_interested_in.split[1]
      new_track = what_class_are_you_interested_in.split(': ').last.split(' ').first
      old_campus = lead.custom['Campus']
      old_track = lead.custom['Track']
      unless new_campus == old_campus && new_track == old_track
        counter += 1
        file.puts "#{lead.contacts.first.name} | #{old_campus} -> #{new_campus} | #{old_track} -> #{new_track}"
        close_io_client.update_lead(lead.id, { 'custom.Campus': new_campus }) if new_campus != old_campus
        close_io_client.update_lead(lead.id, { 'custom.Track': new_track }) if new_track != old_track
      end
    end
  end

  if Rails.env.production? && counter > 0
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: update_campus_and_track");
    mb_obj.set_text_body("rake task: update_campus_and_track");
    mb_obj.add_attachment(filename, "updated_campus_and_track.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "All campus & track fields match what class are you interested in field. :)"
  end
end

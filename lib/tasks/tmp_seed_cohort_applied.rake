desc "seed Cohort Applied field based on What Class Are You Interested In field"
task :tmp_seed_cohort_applied => [:environment] do
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'seed_cohort_applied.txt')
  File.open(filename, 'w') do |file|
    close_io_client.list_leads('"custom.What class are you interested in?":*', 5000)[:data].each do |lead|
      what_class_are_you_interested_in = lead.custom['What class are you interested in?']
      email = lead['contacts'].first['emails'].first['email']

      if what_class_are_you_interested_in.include?('track') || what_class_are_you_interested_in.include?('Part-time')
        office = Office.find_by(name: what_class_are_you_interested_in.split[1])
        year = what_class_are_you_interested_in.split[0].to_i
        start_date_month = Date::MONTHNAMES.index(what_class_are_you_interested_in.split[2])
        start_date_day = what_class_are_you_interested_in.split[3].to_i
        end_date_month = Date::MONTHNAMES.index(what_class_are_you_interested_in.split[5])
        end_date_day = what_class_are_you_interested_in.split[6].to_i
        start_date = Time.new(year, start_date_month, start_date_day).to_date
        end_date = Time.new(year, end_date_month, end_date_day).to_date
        if what_class_are_you_interested_in.include?('Part-time')
          # FROM: 2018 Portland January 3 - April 11: Part-time, evening Intro to Programming
          # TO: PT: 2018-01 PDX Part-time (Jan 3 - Apr 11)
          track = Track.find_by(description: 'Part-time')
          description = "PT: #{start_date.strftime('%Y-%m')} #{office.short_name} #{track.description} (#{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d')})"
        else
          # FROM: 2018 Portland January 2 - July 6: Ruby/Rails track
          # TO: 2018-01 PDX Ruby/Rails (Jan 2 - Jul 6)
          track = Track.find_by(description: what_class_are_you_interested_in.split(': ').last.split(' ').first)
          description = "#{start_date.strftime('%Y-%m')} #{office.short_name} #{track.description} (#{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d')})"
        end
      elsif what_class_are_you_interested_in == 'A later class'
        description = what_class_are_you_interested_in
      else
        description = "Legacy: " + what_class_are_you_interested_in
      end
      file.puts "#{description} | #{what_class_are_you_interested_in} | #{email}"
      close_io_client.update_lead(lead['id'], { 'custom.Cohort - Applied': description })
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: seed_cohort_applied");
    mb_obj.set_text_body("rake task: seed_cohort_applied");
    mb_obj.add_attachment(filename, "seed_cohort_applied.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

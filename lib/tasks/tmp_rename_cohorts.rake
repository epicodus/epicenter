desc "Rename cohorts to match new naming tmp_schemerename_cohorts"
 task :tmp_rename_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_rename_cohorts.txt')
  File.open(filename, 'w') do |file|
    Cohort.where.not('description LIKE ?', '%(%').each do |cohort|
      track_description = cohort.track.try(:description) || "ALL"
      description = "#{cohort.start_date.strftime('%Y-%m')} #{cohort.office.short_name} #{track_description} (#{cohort.start_date.strftime('%b %-d')} - #{cohort.end_date.strftime('%b %-d')})"
      cohort.update_columns(description: description)
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_rename_cohorts");
    mb_obj.set_text_body("rake task: tmp_rename_cohorts");
    mb_obj.add_attachment(filename, "tmp_rename_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

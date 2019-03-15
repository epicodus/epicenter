desc "calculate new cohort names"
task :tmp_update_cohorts3 => [:environment] do
  IGNORE_LIST = ["do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_cohorts3.txt')

  # rename cohorts in Epicenter
  # File.open(filename, 'w') do |file|
  #   Cohort.all.each do |cohort|
  #     if cohort.description == 'Fidgetech'
  #       description = 'Fidgetech'
  #     elsif cohort.track.nil?
  #       description = "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} ALL"
  #     else
  #       description = "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} #{cohort.track.description}"
  #     end
  #     cohort.update_columns(description: description)
  #   end
  # end

  # rename cohorts in Close
  # Student.where.not(starting_cohort: nil).each do |student|
  #   student.crm_lead.update({ 'custom.Cohort - Starting': student.starting_cohort.description })
  # end
  # Student.where.not(cohort: nil).each do |student|
  #   student.crm_lead.update({ 'custom.Cohort - Current': student.cohort.description })
  # end

  # if Rails.env.production?
  #   mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
  #   mb_obj = Mailgun::MessageBuilder.new()
  #   mb_obj.set_from_address("it@epicodus.com");
  #   mb_obj.add_recipient(:to, "mike@epicodus.com");
  #   mb_obj.set_subject("rake task: tmp_update_cohorts3");
  #   mb_obj.set_text_body("rake task: tmp_update_cohorts3");
  #   mb_obj.add_attachment(filename, "tmp_update_cohorts3.txt");
  #   result = mg_client.send_message("epicodus.com", mb_obj)
  #   puts result.body.to_s
  #   puts "Sent #{filename.to_s}"
  # else
  #   puts "Exported #{filename.to_s}"
  # end
end

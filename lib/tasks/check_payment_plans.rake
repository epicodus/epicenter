desc "check payment plans in Close match those in Epicenter"
task :check_payment_plans => [:environment] do
  IGNORE_LIST = ["do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  filename = File.join(Rails.root.join('tmp'), 'incorrect_payment_plans.txt')
  counter = 0
  File.open(filename, 'w') do |file|
    Student.where(cohort_id: Cohort.where('start_date > ?', Date.parse('2018-10-01'))).each do |student|
      unless IGNORE_LIST.include? student.email
        lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
        plan_in_close = lead['custom']['Payment plan']
        if student.plan.try(:close_io_description) != plan_in_close
          file.puts "EPICENTER: #{student.plan.try(:close_io_description)} | CLOSE: #{plan_in_close} | #{student.email}"
          counter += 1
        else
        end
      end
    end
  end
  if Rails.env.production? && counter > 0
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Payment plans not matching");
    mb_obj.set_text_body("rake task: check_payment_plans");
    mb_obj.add_attachment(filename, "incorrect_payment_plans.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "Looks good! All payment plans in Close match those in Epicenter! :)"
  end
end

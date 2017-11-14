desc "Set cohort for students formerly grouped together who dropped before level3"
 task :tmp_clear_ending_cohort => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'updated.txt')
  File.open(filename, 'w') do |file|

    # # NOTE: Check for students with no internship course but cohort listed in Close
    # # NOTE: (all 2016-ALL folks have already been properly adjusted now)
    Student.all.each do |student|
      courses = student.courses.fulltime_courses.reorder(:start_date)
      if student.cohort && courses.any? && courses.internship_courses.empty? && courses.first.start_date > Date.parse('2016-01-01')
        status = student.crm_lead.status
        if status.downcase.split.first == "dropped" || status.downcase.split.first == "expelled"
          file.puts "CLEARING COHORT: #{student.name} | #{status} | #{student.starting_cohort.try(:description)} | #{student.cohort.description}"
          student.update(cohort: nil)
          student.crm_lead.update({ 'custom.Cohort': nil })
        else
          # file.puts "#{student.name} | #{status} | #{student.starting_cohort.try(:description)} | #{student.cohort.description}"
          # student.courses.fulltime_courses.reorder(:start_date).each do |course|
          #   file.puts "  #{course.description}"
          # end
          # file.puts ""
        end
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_clear_ending_cohort");
    mb_obj.set_text_body("rake task: tmp_clear_ending_cohort");
    mb_obj.add_attachment(filename, "updated.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

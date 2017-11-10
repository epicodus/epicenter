desc "Set cohort for students formerly grouped together who dropped before level3"
 task :tmp_split_2016_all_cohorts2 => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'updated.txt')
  File.open(filename, 'w') do |file|

    # update starting cohort based on courses (RUN ON HEROKU)
    Student.where(starting_cohort_id: [22, 23, 24, 25, 26, 27]).where(cohort_id: nil).each do |student|
      # starting_cohort set to ALL and dropped out so cohort blank
      courses = student.courses_with_withdrawn.reorder(:start_date)
      if courses.level(1).any?
        track = Track.find_by('description like ?', '%' + courses.level(1).last.description.split.last + '%')
        start_date = courses.first.start_date
        office = courses.first.office
        description = "#{start_date.strftime('%Y-%m')} #{track.description} #{office.name}"
        cohort = Cohort.find_by(description: description, track: track, office: office, start_date: start_date)
        if cohort
          student.update(starting_cohort: cohort)
          # student.crm_lead.update({ 'custom.Starting Cohort': cohort.description })
          file.puts "#{student.name} | #{cohort.description}"
        end
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_split_2016_all_cohorts2");
    mb_obj.set_text_body("rake task: tmp_split_2016_all_cohorts2");
    mb_obj.add_attachment(filename, "updated.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

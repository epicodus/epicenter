desc "find leads in Close missing starting cohort"
task :find_leads_missing_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'find_leads_missing_cohorts.txt')
  File.open(filename, 'w') do |file|

    Course.where(track: nil, internship_course: false).each do |course|
      calculated_track = Track.find_by('description LIKE ?', '%' + course.description.split.last + '%')
      if calculated_track
        file.puts "#{course.description} | #{calculated_track.try(:description)}"
        course.update(track: calculated_track)
      else
        file.puts "SKIPPED: #{course.description}"
      end
    end
  end

  # IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  # close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  # fulltime_students_who_should_have_starting_cohort_assigned = Student.with_deleted.select { |s| s.courses_with_withdrawn.fulltime_courses.any? && s.courses_with_withdrawn.fulltime_courses.first.start_date > Date.parse('2016-01-01') }
  # fulltime_students_who_should_have_starting_cohort_assigned.each do |student|
  #   unless IGNORE_LIST.include? student.email
  #     lead = close_io_client.list_leads('email:' + student.email)['data'].first
  #     close_starting_cohort = lead['custom']['Cohort - Starting']
  #     calculated_starting_cohort = student.courses_with_withdrawn.fulltime_courses.first.cohorts.first
  #
  #     if student.starting_cohort.nil? || close_starting_cohort.nil?
  #       puts "#{student.email}: Missing starting_cohort in Close and/or Epicenter"
  #     elsif student.starting_cohort.description != close_starting_cohort
  #       puts "#{student.email}: Close starting_cohort does not match Epicenter starting_cohort"
  #     elsif student.starting_cohort != calculated_starting_cohort
  #       if calculated_starting_cohort.try('description').try('include?', 'ALL') && student.starting_cohort.description.split.first == calculated_starting_cohort.try(:description).try(:split).try(:first)
  #         # ignore (starting cohort is more accurate than calculated one that contains ALL)
  #       else
  #         puts "#{student.email}: starting_cohort: #{student.starting_cohort.description} | calculated: #{student.courses_with_withdrawn.fulltime_courses.first.cohorts.first.try(:description)}"
  #       end
  #     end
  #
  #   end
  # end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Duplicate or missing Close leads");
    mb_obj.set_text_body("rake task: find_leads_missing_cohorts");
    mb_obj.add_attachment(filename, "find_leads_missing_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

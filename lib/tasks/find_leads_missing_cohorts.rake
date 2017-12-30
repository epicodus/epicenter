desc "find leads in Close missing starting cohort"
task :find_leads_missing_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'find_leads_missing_cohorts.txt')
  File.open(filename, 'w') do |file|

    IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
    close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    fulltime_students_who_should_have_starting_cohort_assigned = Student.with_deleted.select { |s| s.courses_with_withdrawn.fulltime_courses.any? && s.courses_with_withdrawn.fulltime_courses.first.start_date > Date.parse('2016-01-01') }
    fulltime_students_who_should_have_starting_cohort_assigned.each do |student|
      unless IGNORE_LIST.include? student.email

        # try to calculate starting cohort
        courses = student.courses_with_withdrawn.fulltime_courses.non_internship_courses
        if courses.first.cohorts.count == 1
          calculated_starting_cohort = courses.first.cohorts.first
        elsif courses.map {|c| c.track}.compact.empty? # no courses with associated track, so use an 'all' cohort
          calculated_starting_cohort = courses.first.cohorts.find_by('description LIKE ?', '%ALL%')
        else
          # calculate cohort start date based on first course level and start date
          if courses.first.start_date.to_s == '2016-01-04'
            cohort_start_date = '2016-01-04'
          else
            start_dates = Course.fulltime_courses.where(office: Office.find_by(name: 'Portland')).reorder(:start_date).map {|c| c.start_date.to_s}.uniq
            cohort_start_date = start_dates[start_dates.find_index(courses.first.start_date.to_s) - courses.first.language.level]
          end
          courses_with_tracks = courses.select { |c| c.track.present? }
          calculated_starting_cohort = courses.first.cohorts.find_by(track: courses_with_tracks.first.track, start_date: cohort_start_date)
          calculated_starting_cohort = courses_with_tracks.first.cohorts.find_by(track: courses_with_tracks.first.track, start_date: cohort_start_date) if calculated_starting_cohort.nil?
          calculated_starting_cohort = courses.first.cohorts.find_by('description LIKE ?', '%ALL%') if calculated_starting_cohort.nil?
        end

        # compare calculated starting cohort to existing student.starting_cohort & update if needed
        if calculated_starting_cohort.nil?
          file.puts "#{student.email}: Unable to calculate starting cohort"
        elsif student.starting_cohort.nil?
          file.puts "#{student.email}: Missing starting cohort in Epicenter"
        elsif student.starting_cohort.description != calculated_starting_cohort.description
          file.puts "#{student.email}: Updating starting_cohort: #{student.starting_cohort.description} ==> #{calculated_starting_cohort.description}"
          student.update(starting_cohort: calculated_starting_cohort)
          student.crm_lead.update({ 'custom.Cohort - Starting': calculated_starting_cohort.description })
        end

        # check starting_cohort in Close matches starting_cohort in Epicenter
        lead = close_io_client.list_leads('email:' + student.email)['data'].first
        close_starting_cohort = lead['custom']['Cohort - Starting']
        if close_starting_cohort.nil?
          file.puts "ERROR: #{student.email}: Missing starting_cohort in Close"
        elsif student.starting_cohort.description != close_starting_cohort
          file.puts "ERROR: #{student.email}: Close starting_cohort does not match Epicenter starting_cohort"
        end

      end
    end
  end

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

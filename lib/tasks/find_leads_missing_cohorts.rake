desc "find leads in Close missing starting cohort"
task :find_leads_missing_cohorts => [:environment] do
  counter = 0
  filename = File.join(Rails.root.join('tmp'), 'find_leads_missing_cohorts.txt')
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  File.open(filename, 'w') do |file|

    # ********************* #
    # STARTING COHORT CHECK #
    # ********************* #
    fulltime_students_who_should_have_starting_cohort_assigned = Student.with_deleted.select { |s| s.courses_with_withdrawn.fulltime_courses.any? && s.courses_with_withdrawn.fulltime_courses.first.start_date > Date.parse('2016-01-01') }
    fulltime_students_who_should_have_starting_cohort_assigned.each do |student|
      unless IGNORE_LIST.include? student.email
        calculated_starting_cohort = student.calculate_starting_cohort

        # compare calculated starting cohort to existing student.starting_cohort
        if calculated_starting_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Unable to calculate starting cohort"
        elsif student.starting_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Missing starting cohort in Epicenter"
        elsif student.starting_cohort.description != calculated_starting_cohort.description
          counter += 1
          file.puts "#{student.email}: Starting cohort should be updated: #{student.starting_cohort.description} ==> #{calculated_starting_cohort.description}"
          student.update(starting_cohort: calculated_starting_cohort)
          student.crm_lead.update({ 'custom.Cohort - Starting': calculated_starting_cohort.description })
        end

        # check starting_cohort in Close matches starting_cohort in Epicenter
        # lead = close_io_client.list_leads('email:' + student.email)['data'].first
        # close_starting_cohort = lead['custom']['Cohort - Starting']
        # if close_starting_cohort.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing starting_cohort in Close"
        # elsif student.starting_cohort.description != close_starting_cohort
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close starting_cohort does not match Epicenter starting_cohort"
        # end
      end
    end

    # ******************** #
    # CURRENT COHORT CHECK #
    # ******************** #
    fulltime_students_who_should_have_current_cohort_assigned = Student.select {|s| s.courses.internship_courses.any? && s.courses.internship_courses.last.start_date > Date.parse('2016-01-01')}
    fulltime_students_who_should_have_current_cohort_assigned.each do |student|
      unless IGNORE_LIST.include? student.email
        calculated_current_cohort = student.calculate_current_cohort

        # compare calculated current cohort to existing student.cohort
        if calculated_current_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Unable to calculate current cohort"
        elsif student.cohort.nil?
          counter += 1
          file.puts "#{student.email}: Missing cohort in Epicenter"
        elsif student.cohort.description != calculated_current_cohort.description
          counter += 1
          file.puts "#{student.email}: Current Cohort should be updated: #{student.cohort.description} ==> #{calculated_current_cohort.description}"
          student.update(cohort: calculated_current_cohort)
          student.crm_lead.update({ 'custom.Cohort - Current': calculated_current_cohort.description })
        end

        # # check current cohort in Close matches cohort in Epicenter
        # lead = close_io_client.list_leads('email:' + student.email)['data'].first
        # close_current_cohort = lead['custom']['Cohort - Current']
        # if close_current_cohort.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing current cohort in Close"
        # elsif student.cohort.description != close_current_cohort
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close current cohort does not match Epicenter cohort"
        # end
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Leads missing cohorts");
    mb_obj.set_text_body("rake task: find_leads_missing_cohorts");
    mb_obj.add_attachment(filename, "find_leads_missing_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "Looks good! All starting cohorts in Epicenter & Close are as expected."
  end
end

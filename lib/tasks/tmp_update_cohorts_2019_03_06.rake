desc "merge PT cohorts into starting & current cohorts"
task :tmp_update_cohorts_2019_03_06 => [:environment] do
  counter = 0
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_cohorts_2019_03_06.txt')
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  File.open(filename, 'w') do |file|

    # ********************* #
    # STARTING COHORT CHECK #
    # ********************* #

    fulltime_students_who_should_have_starting_cohort_assigned = Student.with_deleted.select { |s| s.courses_with_withdrawn.any? && s.courses_with_withdrawn.first.start_date > Date.parse('2017-01-01') }
    fulltime_students_who_should_have_starting_cohort_assigned.each do |student|
      unless IGNORE_LIST.include? student.email
        calculated_starting_cohort = student.calculate_starting_cohort

        # compare calculated starting cohort to existing student.starting_cohort
        if calculated_starting_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Unable to calculate starting cohort"
          # log(student, file)
        elsif student.starting_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Missing starting cohort in Epicenter"
          # log(student, file) if student.courses_with_withdrawn.fulltime_courses.any?
          student.update(starting_cohort: calculated_starting_cohort)
          student.crm_lead.update({ Rails.application.config.x.crm_fields['COHORT_STARTING'] => calculated_starting_cohort.description, Rails.application.config.x.crm_fields['START_DATE'] => calculated_starting_cohort.start_date.to_s })
        elsif student.starting_cohort.description != calculated_starting_cohort.description
          counter += 1
          file.puts "#{student.email}: Starting cohort should be updated: #{student.starting_cohort.description} ==> #{calculated_starting_cohort.description}"
          # log(student, file)
          # student.update(starting_cohort: calculated_starting_cohort)
          # student.crm_lead.update({ Rails.application.config.x.crm_fields['COHORT_STARTING'] => calculated_starting_cohort.description, Rails.application.config.x.crm_fields['START_DATE'] => calculated_starting_cohort.start_date.to_s })
        end

        # check starting_cohort & start date in Close matches starting_cohort in Epicenter
        # lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
        # close_starting_cohort = lead['custom'][Rails.application.config.x.crm_fields['COHORT_STARTING']]
        # close_start_date = lead['custom'][Rails.application.config.x.crm_fields['START_DATE']]
        # if close_starting_cohort.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing starting_cohort in Close"
        # elsif close_start_date.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing start date in Close"
        # elsif student.starting_cohort.description != close_starting_cohort
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close starting_cohort does not match Epicenter starting_cohort"
        # elsif student.starting_cohort.start_date.to_s != close_start_date
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close start date does not match Epicenter starting_cohort start date"
        # end
      end
    end #starting cohort check

    # ******************** #
    # CURRENT COHORT CHECK #
    # ******************** #
    #
    fulltime_students_who_should_have_current_cohort_assigned = Student.select {|s| (s.courses.internship_courses.any? || s.courses.parttime_courses.any?) && s.courses.first.start_date > Date.parse('2017-01-01')}
    fulltime_students_who_should_have_current_cohort_assigned.each do |student|
      unless IGNORE_LIST.include? student.email
        calculated_current_cohort = student.calculate_current_cohort

        # compare calculated current cohort to existing student.cohort
        if calculated_current_cohort.nil?
          counter += 1
          file.puts "#{student.email}: Unable to calculate current cohort"
          # log(student, file)
        elsif student.cohort.nil?
          counter += 1
          file.puts "#{student.email}: Missing cohort in Epicenter"
          # log(student, file) if student.courses.internship_courses.any?
          student.update(cohort: calculated_current_cohort)
          student.crm_lead.update({ Rails.application.config.x.crm_fields['COHORT_CURRENT'] => calculated_current_cohort.description, Rails.application.config.x.crm_fields['END_DATE'] => calculated_current_cohort.end_date.to_s })
        elsif student.cohort.description != calculated_current_cohort.description
          counter += 1
          file.puts "#{student.email}: Current Cohort should be updated: #{student.cohort.description} ==> #{calculated_current_cohort.description}"
          # log(student, file)
          # student.update(cohort: calculated_current_cohort)
          # student.crm_lead.update({ Rails.application.config.x.crm_fields['COHORT_CURRENT'] => calculated_current_cohort.description, Rails.application.config.x.crm_fields['END_DATE'] => calculated_current_cohort.end_date.to_s })
        end

        # check current cohort & end date in Close matches cohort in Epicenter
        # lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
        # close_current_cohort = lead['custom'][Rails.application.config.x.crm_fields['COHORT_CURRENT']]
        # close_end_date = lead['custom'][Rails.application.config.x.crm_fields['END_DATE']]
        # if close_current_cohort.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing current cohort in Close"
        # elsif close_end_date.nil?
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Missing end date in Close"
        # elsif student.cohort.description != close_current_cohort
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close current cohort does not match Epicenter cohort"
        # elsif student.cohort.end_date.to_s != close_end_date
        #   counter += 1
        #   file.puts "ERROR: #{student.email}: Close end date does not match Epicenter cohort end date"
        # end
      end
    end #current cohort check

  end #File.open

  if Rails.env.production? && counter > 0
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("Leads missing cohorts");
    mb_obj.set_text_body("rake task: tmp_update_cohorts_2019_03_06");
    mb_obj.add_attachment(filename, "tmp_update_cohorts_2019_03_06.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  elsif counter > 0
    puts "Exported #{filename.to_s}"
  else
    puts "Looks good! All starting and current cohorts in Epicenter & Close are as expected."
  end
end

def log(student, file)
  file.puts "Calculated Cohort STARTING: #{student.calculate_starting_cohort.try(:description)}"
  file.puts "Calculated Cohort CURRENT: #{student.calculate_current_cohort.try(:description)}"
  student.enrollments.each do |enrollment|
    file.puts enrollment.course.try(:description) || "enrollment not found"
  end
  student.enrollments.only_deleted.each do |enrollment|
    file.puts "#{enrollment.course.try(:description)} (withdrawn)"
  end
  file.puts ''
end

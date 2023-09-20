desc "find leads in Close missing starting cohort"
task :find_leads_missing_cohorts => [:environment] do
  counter = 0
  filename = File.join(Rails.root.join('tmp'), 'find_leads_missing_cohorts.txt')
  close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  students = Student.where.not(id: students_to_skip)
  File.open(filename, 'w') do |file|

    # ********************* #
    # STARTING COHORT CHECK #
    # ********************* #
    ft_starting_cohort_students = students.select { |s| has_pertinent_courses?(s.courses_with_withdrawn.fulltime_courses) || has_pertinent_courses?(s.courses_with_withdrawn.parttime_full_stack_courses) }
    ft_starting_cohort_students.each do |student|
      calculated_starting_cohort = student.calculate_starting_cohort

      # compare calculated starting cohort to existing student.starting_cohort
      if calculated_starting_cohort.nil? && student.courses.first.start_date > Date.parse('2018-01-01')
        counter += 1
        file.puts "#{student.email}: Unable to calculate starting cohort"
        # log(student, file)
      elsif student.starting_cohort.nil? && student.courses.first.start_date > Date.parse('2018-01-01')
        counter += 1
        file.puts "#{student.email}: Missing starting cohort in Epicenter"
        # log(student, file) if student.courses_with_withdrawn.fulltime_courses.any?
      elsif student.starting_cohort.try(:description) != calculated_starting_cohort.try(:description)
        counter += 1
        file.puts "#{student.email}: Starting cohort should be updated: #{student.starting_cohort.description} ==> #{calculated_starting_cohort.description}"
        # log(student, file)
      end

      # check starting_cohort in Close matches starting_cohort in Epicenter
      # lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
      # close_starting_cohort = lead[Rails.application.config.x.crm_fields['COHORT_STARTING']]
      # if close_starting_cohort.nil?
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Missing starting_cohort in Close"
      # elsif student.starting_cohort.description != close_starting_cohort
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Close starting_cohort does not match Epicenter starting_cohort"
      # end
    end #starting cohort check

    # ******************** #
    # CURRENT COHORT CHECK #
    # ******************** #
    ft_current_cohort_students = students.select {|s| has_pertinent_courses?(s.courses.internship_courses) || has_pertinent_courses?(s.courses.parttime_full_stack_courses) }
    ft_current_cohort_students.each do |student|
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
      elsif student.cohort.description != calculated_current_cohort.description
        counter += 1
        file.puts "#{student.email}: Current Cohort should be updated: #{student.cohort.description} ==> #{calculated_current_cohort.description}"
        # log(student, file)
      end

      # check current cohort in Close matches cohort in Epicenter
      # lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
      # close_current_cohort = lead[Rails.application.config.x.crm_fields['COHORT_CURRENT']]
      # if close_current_cohort.nil?
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Missing current cohort in Close"
      # elsif student.cohort.description != close_current_cohort
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Close current cohort does not match Epicenter cohort"
      # end
    end #current cohort check

    # ********************* #
    # PARTTIME COHORT CHECK #
    # ********************* #
    parttime_students = students.select {|s| has_pertinent_courses?(s.courses.parttime_intro_courses) }
    parttime_students.each do |student|
      calculated_parttime_cohort = student.calculate_parttime_cohort

      # compare calculated parttime cohort to existing student.parttime_cohort
      if calculated_parttime_cohort.nil?
        counter += 1
        file.puts "#{student.email}: Unable to calculate parttime cohort"
        # log(student, file)
      elsif student.parttime_cohort.nil?
        counter += 1
        file.puts "#{student.email}: Missing parttime cohort in Epicenter"
        # log(student, file) if student.courses.parttime_courses.any?
      elsif student.parttime_cohort.description != calculated_parttime_cohort.description
        counter += 1
        file.puts "#{student.email}: Parttime Cohort should be updated: #{student.parttime_cohort.description} ==> #{calculated_parttime_cohort.description}"
        # log(student, file)
      end

      # check parttime cohort in Close matches parttime_cohort in Epicenter
      # lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
      # close_parttime_cohort = lead[Rails.application.config.x.crm_fields['COHORT_PARTTIME']]
      # if close_parttime_cohort.nil?
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Missing parttime cohort in Close"
      # elsif student.parttime_cohort.description != close_parttime_cohort
      #   counter += 1
      #   file.puts "ERROR: #{student.email}: Close parttime cohort does not match Epicenter parttime_cohort"
      # end
    end #parttime cohort check

  end #File.open

  if Rails.env.production? && counter > 0
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
    puts "Looks good! All starting, current, and part-time cohorts in Epicenter & Close are as expected."
  end
end

# helpers

def log(student, file)
  file.puts "Calculated Cohort STARTING: #{student.calculate_starting_cohort.try(:description)}"
  file.puts "Calculated Cohort CURRENT: #{student.calculate_current_cohort.try(:description)}"
  file.puts "Calculated Cohort PARTTIME: #{student.calculate_parttime_cohort.try(:description)}"
  student.enrollments.each do |enrollment|
    file.puts enrollment.course.try(:description) || "enrollment not found"
  end
  student.enrollments.only_deleted.each do |enrollment|
    file.puts "#{enrollment.course.try(:description)} (withdrawn)"
  end
  file.puts ''
end

def has_pertinent_courses?(courses)
  courses.any? && (courses.non_internship_courses.last.try(:end_date) &.> Date.parse('2019-01-01'))
end

def students_to_skip
  test_students = Student.select { |student| student.email.include?('mortalwombat.net') || student.email.include?('example.com') || student.email.include?('epicodus.com') }
  fidgetech_students = Student.select { |student| student.courses_with_withdrawn.last.try(:description) == 'Fidgetech' }
  test_students + fidgetech_students
end

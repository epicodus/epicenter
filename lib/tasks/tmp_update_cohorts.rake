desc "Merge part-time cohort into starting & current cohort fields"
 task :tmp_update_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_cohorts.txt')
  File.open(filename, 'w') do |file|
    # students = Student.where.not(parttime_cohort: nil)

    # students = students.select {|s| s.courses_with_withdrawn.internship_courses.any? && (s.calculate_starting_cohort.description.include?('PT') || s.calculate_current_cohort.description.include?('PT')) }
    # students = students.select {|s| s.courses_with_withdrawn.internship_courses.empty? && s.calculate_starting_cohort.nil? }
    # students = students.select {|s| s.courses_with_withdrawn.internship_courses.empty? && (s.courses.parttime_courses.empty? && s.calculate_current_cohort.present?) }

    # students = Student.all.select {|s| s.starting_cohort != s.calculate_starting_cohort}

    students.each do |student|
      file.puts "#{student.calculate_starting_cohort.try(:description)} | #{student.calculate_current_cohort.try(:description)} | #{student.email}"
      student.courses_with_withdrawn.each do |course|
        if student.courses.include? course
          file.puts 'ENROLLED: ' + course.description
        else
          file.puts 'withdrawn: ' + course.description
        end
      end
      file.puts ''
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_update_cohorts");
    mb_obj.set_text_body("rake task: tmp_update_cohorts");
    mb_obj.add_attachment(filename, "tmp_update_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

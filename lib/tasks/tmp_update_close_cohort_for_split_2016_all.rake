desc "Set CRM cohort to match Epicenter cohort for students split with tmp_split_2016_all_cohorts"
task :tmp_update_close_cohort_for_split_2016_all => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_close_cohort_for_split_2016_all.txt')
  File.open(filename, 'w') do |file|
    students_to_update = []
    Cohort.where('description LIKE ?', '%ALL%').each do |cohort|
      cohort.courses.level(3).each do |course|
        course.students.each do |student|
          students_to_update << { student: student, course: course }
        end
      end
    end
    students_to_update.each do |params|
      student = params[:student]
      course = params[:course]
      cohort = student.courses.level(3).reorder(:start_date).last.cohorts.select {|cohort| !cohort.description.include?('ALL')}.first
      file.puts "WARNING: #{student.name}" unless cohort == student.cohort
      student.crm_lead.update({ 'custom.Cohort': student.cohort.description })
      file.puts "#{cohort.description } | #{course.description} | #{student.name}"
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_update_close_cohort_for_split_2016_all");
    mb_obj.set_text_body("rake task: tmp_update_close_cohort_for_split_2016_all");
    mb_obj.add_attachment(filename, "tmp_update_close_cohort_for_split_2016_all.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

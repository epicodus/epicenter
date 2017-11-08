# note: this correctly accounts for the one student w/ multiple level 3 courses
desc "Set cohort for students formerly grouped together"
task :tmp_split_2016_all_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'updated.txt')
  File.open(filename, 'w') do |file|
    file.puts "CREATING NEW COHORTS:"
    file.puts ""
    students_to_update = []
    Cohort.where('description LIKE ?', '%ALL%').each do |cohort|
      file.puts "SPLITTING COHORT: #{cohort.description}"
      cohort.courses.level(3).each do |course|
        courses = []
        course.students.each do |student|
          students_to_update << { student: student, course: course }
          student.courses.fulltime_courses.reorder(:start_date).each do |c|
            if c.cohorts.first == cohort
              if c.language.level == 1 || c.language.level == 3
                courses << c if Track.find_by('description LIKE ?', '%' + course.description.split[1] + '%').description.include? c.description.split[1]
              else
                courses << c
              end
            end
          end
        end
        courses.uniq!
        courses = Course.where(id: courses.pluck(:id)).reorder(:start_date)
        course_ids = courses.map {|c| c.id}
        start_date = courses.first.start_date
        track = Track.find_by('description LIKE ?', '%' + course.description.split[1] + '%')
        office = course.office
        description = "#{start_date.strftime('%Y-%m')} #{track.description} #{office.name}"
        admin = Admin.find_by_id(course.admin_id) || Admin.find(11)
        new_cohort = Cohort.new(description: description, track: track, office: office, admin: admin, start_date: start_date, course_ids: course_ids)
        new_cohort.save(validate: false)
        file.puts "Cohort created: #{description}"
        courses.each do |c|
          file.puts "  #{c.id} | #{c.description} | level #{c.language.level}"
        end
      end
      file.puts ""
    end

    file.puts "----------------------------------------------------------------"
    file.puts "UPDATING STUDENTS:"
    file.puts "cohort | level_3_course | name"
    file.puts ""
    students_to_update.each do |params|
      student = params[:student]
      course = params[:course]
      cohort = student.courses.level(3).reorder(:start_date).last.cohorts.select {|cohort| !cohort.description.include?('ALL')}.first
      student.update(cohort: cohort)
      # student.crm_lead.update({ 'custom.Cohort': cohort.description })
      file.puts "#{cohort.description } | #{course.description} | #{student.name}"
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_split_2016_all_cohorts");
    mb_obj.set_text_body("rake task: tmp_split_2016_all_cohorts");
    mb_obj.add_attachment(filename, "updated.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

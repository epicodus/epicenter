task :tmp_create_legacy_internship_courses => [:environment] do
  Course.select {|c| c.cohorts.count > 1}.each do |course|
    puts "#{course.id} #{course.description}"
    cohorts = course.cohorts
    cohorts.each_with_index do |cohort, index|
      puts "#{index} #{cohort.description}"
      if index > 0

        track = cohort.track
        office = course.office
        admin = course.admin
        language = course.language
        internship_course = course.internship_course
        parttime = course.parttime
        class_times = course.class_times        
        class_days = course.class_days
        start_date = course.start_date
        end_date = course.end_date
        description = course.description + ' [placeholder]'

        puts ""
        puts "track: #{track.try(:description)}"
        puts "office: #{office.short_name}"
        puts "admin: #{admin.try(:name)}"
        puts "start_date: #{start_date.to_s}"
        puts "end_date: #{end_date.to_s}"
        puts "language: #{language.name}"        
        puts "number of class days: #{class_days.count}"
        puts "number of class times: #{class_times.count}"
        puts "internship course" if internship_course
        puts "parttime" if parttime
        puts "description: #{description}"
        puts ""

        new_course = Course.create({ track: track, office: office, admin: admin, language: language, start_date: start_date, end_date: end_date, class_days: class_days, class_times: class_times, description: description, internship_course: internship_course, parttime: parttime })
        cohort.courses.delete(course)
        cohort.courses << new_course
      end
    end
    puts ''
    puts '---'
    puts ''
  end
end

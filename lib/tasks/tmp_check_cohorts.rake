desc "Check starting and current cohort set correctly"
task :tmp_check_cohorts => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_check_cohorts.txt')
  File.open(filename, 'w') do |file|
    file.puts "Starting Cohort May Not Match:"
    Student.where.not(starting_cohort: nil).each do |student|
      calculated_cohort = get_starting_cohort(student)
      unless student.starting_cohort == calculated_cohort
        unless calculated_cohort.try(:description).try('include?', 'ALL') && student.starting_cohort.start_date == calculated_cohort.try(:start_date)
          file.puts "#{student.starting_cohort.try(:description)} | #{calculated_cohort.try(:description)} | #{student.email}"
        end
      end
    end

    file.puts "Cohort May Not Match:"
    Student.where.not(cohort: nil).each do |student|
      calculated_cohort = get_current_cohort(student)
      unless student.cohort == calculated_cohort || calculated_cohort.try(:description).include?('ALL')
        file.puts "#{student.cohort.try(:description)} | #{calculated_cohort.try(:description)} | #{student.email}"
      end
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: tmp_check_cohorts");
    mb_obj.set_text_body("rake task: tmp_check_cohorts");
    mb_obj.add_attachment(filename, "tmp_check_cohorts.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end

def get_starting_cohort(student)
  if student.courses_with_withdrawn.fulltime_courses.any?
    cohort = nil
    student.courses_with_withdrawn.fulltime_courses.each do |course|
      cohort = course.cohorts.first if course.cohorts.count == 1 && cohort.nil?
    end
    cohort
  else
    student.courses_with_withdrawn.parttime_courses.first.try(:cohorts).try(:first)
  end
end

def get_current_cohort(student)
  return nil if student.courses.internship_courses.empty?
  last_course = student.courses.fulltime_courses.order(:start_date).last
  if last_course.cohorts.count == 1
    last_course.cohorts.first
  else
    student.courses.level(3).order(:start_date).last.try(:cohorts).try(:first) || student.courses.level(1).order(:start_date).last.try(:cohorts).try(:first)
  end
end

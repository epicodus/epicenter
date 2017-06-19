# get all students who EVER took at least 1 day of a course in any cohort that ended between x and y dates
# usage: rake get_students_in_cohorts or rake "get_students_in_cohorts[yyyy-mm-dd, yyyy-mm-dd]"
desc "get students who ever took courses in cohorts ending between certain dates"
task :get_students_in_cohorts, [:start_date, :end_date] => [:environment] do |t, args|
  start_date = args.start_date || ""
  end_date = args.end_date || ""
  while start_date.length != 10
    puts "Enter start date of time period in format yyyy-mm-dd:"
    start_date = STDIN.gets.chomp
  end
  while end_date.length != 10
    puts "Enter end date of time period in format yyyy-mm-dd:"
    end_date = STDIN.gets.chomp
  end
  start_date = Date.parse(start_date)
  end_date = Date.parse(end_date)
  students = []
  cohorts = Cohort.where('end_date >= ? AND end_date <= ?', start_date, end_date)
  cohorts.each do |cohort|
    cohort.courses.each do |course|
      course.enrollments.with_deleted.each do |enrollment|
        students << enrollment.student
      end
    end
  end
  students.uniq!.compact!
  students.each do |student|
    puts "#{student.name} - #{student.email}"
  end
end

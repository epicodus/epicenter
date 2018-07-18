desc "list all students who graduated from each cohort, with amount paid"
task :tmp_all_graduates_with_cohorts_and_total_paid => [:environment] do
  IGNORE_LIST = ["test@mortalwombat.net", "do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  filename = File.join(Rails.root.join('tmp'), 'tmp_all_graduates_with_cohorts_and_total_paid.txt')
  File.open(filename, 'w') do |file|
    cohorts = Cohort.where('start_date > ? AND start_date < ?', Date.parse('2017-01-01'), Date.parse('2018-01-01')).order(:start_date)
    calculate_results({location: "PDX", fulltime: true, file: file, cohorts: cohorts})
    calculate_results({location: "SEA", fulltime: true, file: file, cohorts: cohorts})
    calculate_results({location: "PDX", fulltime: false, file: file, cohorts: cohorts})
    calculate_results({location: "SEA", fulltime: false, file: file, cohorts: cohorts})
  end
end

def calculate_results(attributes)
  file = attributes[:file]
  cohorts = attributes[:cohorts]
  office = Office.find_by(short_name: attributes[:location])
  is_fulltime = attributes[:fulltime]

  # file.puts "#{is_fulltime ? "FULLTIME" : "PART-TIME"} #{office.name.upcase}:"
  # file.puts ""
  if is_fulltime
    cohorts.where.not('description LIKE ?', '%PT%').where(office: office).each do |cohort|
      # file.puts "#{cohort.description} - #{cohort.courses.internship_courses.last.students.count} students graduated"
      cohort.courses.internship_courses.last.students.each do |student|
        file.puts "#{cohort.description}, #{student.email}, $#{student.total_paid / 100}"
      end
      # file.puts ""
    end
  else
    cohorts.where('description LIKE ?', '%PT%').where(office: office).each do |cohort|
      # file.puts "#{cohort.description} - #{cohort.courses.map {|course| course.students}.flatten.count} students graduated"
      cohort.courses.each do |course|
        course.students.each do |student|
          file.puts "#{cohort.description}, #{student.email}, $#{student.total_paid / 100}"
        end
      end
      # file.puts ""
    end
  end
  # file.puts "--------"
  # file.puts ""
end

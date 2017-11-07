# for courses beginning after 2017-09-01 (formatting of older entries in CLose is different)
desc "retroactively add internship course for students in Close"
task :tmp_update_internship_course_in_close => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'updated.txt')
  File.open(filename, 'w') do |file|
    Course.level(4).where('start_date > ?', Date.parse('2017-09-01')).order(:office_id).order(:start_date).each do |course|
      course.students.each do |student|
        student.crm_lead.update_internship_class(course)
        file.puts "UPDATED: #{course.description} (#{course.office.name}) - #{student.name}"
      end
      file.puts ""
    end
  end
  puts "Exported #{filename.to_s}"
end

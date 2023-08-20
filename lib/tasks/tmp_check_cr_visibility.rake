desc "time travel to check cr visibility"
task :tmp_check_cr_visibility => [:environment] do
  Timecop.travel(Time.zone.now + 1.day) do
    past_code_reviews = CodeReview.where(course: Course.current_courses).where('visible_date < ?', Date.today)
    binding.pry
    past_code_reviews.each do |cr|
      students = cr.course.students
      students.each do |student|
        if cr.visible?(student)
          # puts "#{cr.title} is visible for #{student.name}"
        elsif cr.expectations_met_by?(student)
          # puts "#{cr.title} is not visible for #{student.name} because expectations are met"
        elsif cr.past_due?(student)
          puts "#{cr.title} is not visible for #{student.name} because PAST_DUE: #{cr.due_date}"
        else
          binding.pry
        end
      end
    end
  end
end

task :tmp_cleanup_legacy_course_cohorts => [:environment] do
  Course.select {|c| c.cohorts.count > 1}.each do |course|
    cohort_ids = course.cohort_ids
    cohort_start_dates = course.cohorts.pluck(:start_date)
    cohort_end_dates = course.cohorts.pluck(:end_date)
    cohort_descriptions = course.cohorts.pluck(:description)
    student_starting_cohorts = course.students.pluck(:starting_cohort_id)
    student_current_cohorts = course.students.pluck(:cohort_id)

    puts "#{course.description} [#{course.id}]"
    course.cohorts.each { |cohort| puts "#{cohort.description} [#{cohort.id}]" }
    puts ""

    course.cohorts = [course.cohorts.first]

    binding.pry if Cohort.where(id: cohort_ids).pluck(:start_date) != cohort_start_dates
    binding.pry if Cohort.where(id: cohort_ids).pluck(:end_date) != cohort_end_dates
    binding.pry if Cohort.where(id: cohort_ids).pluck(:description) != cohort_descriptions
    binding.pry if course.students.reload.pluck(:starting_cohort_id) != student_starting_cohorts
    binding.pry if course.students.reload.pluck(:cohort_id) != student_current_cohorts
  end
end


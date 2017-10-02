# NOTE BEFORE USE: CLEAR EXISTING STARTING & ENDING COHORT FIELDS FROM CLOSE FIRST
# retroactively add starting and ending cohort to students in Epicenter & Close (where cohort exists)
desc "retroactively add starting and ending cohort to students in Epicenter & Close"
task :tmp_update_cohorts_in_close => [:environment] do
  IGNORE_LIST = ["do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
  Student.all.each do |student|
    unless IGNORE_LIST.include? student.email
      if student.courses_with_withdrawn.fulltime_courses.any? && student.courses_with_withdrawn.fulltime_courses.last.cohorts.any? && student.courses_with_withdrawn.fulltime_courses.first.cohorts.any?
      # continue if student has fulltime courses and both first and last course belong to cohort(s)
      # NOTE: there are 3 special case students with last course that belongs to cohort but first course does not - ignoring for now
      # CONFIRMED: all first_course here have exactly 1 cohort
      # CONFIRMED: all last_course with multiple cohorts are internship courses and all those students have a level 3 course with exactly 1 cohort
        first_course = student.courses_with_withdrawn.fulltime_courses.first
        last_course = student.courses_with_withdrawn.fulltime_courses.last

        new_starting_cohort = first_course.cohorts.first
        if last_course.cohorts.count == 1
          new_ending_cohort = last_course.cohorts.first
        else
          new_ending_cohort = student.courses.level(3).last.cohorts.first
        end

        student.update(starting_cohort: new_starting_cohort)
        student.update(ending_cohort: new_ending_cohort)
        crm_update = {}
        crm_update = crm_update.merge({ 'custom.Starting Cohort': new_starting_cohort.description })
        crm_update = crm_update.merge({ 'custom.Ending Cohort': new_ending_cohort.description })

        if student.starting_cohort == student.ending_cohort
          puts "#{student.email}: #{student.starting_cohort.description}"
        else
          puts "#{student.email}: #{student.starting_cohort.description} - #{student.ending_cohort.description}"
        end
        student.crm_lead.update(crm_update) if crm_update.present?
      end
    end
  end
end

class SeedParttimeCohort < ActiveRecord::Migration[5.1]
  def up
    Student.select { |student| student.courses_with_withdrawn.parttime_courses.any? }.each do |student|
      student.update(parttime_cohort: student.courses_with_withdrawn.parttime_courses.last.cohorts.first)
    end
  end
end

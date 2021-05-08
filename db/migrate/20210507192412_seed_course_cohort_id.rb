class SeedCourseCohortId < ActiveRecord::Migration[5.2]
  def up
    Course.all.each do |course|
      course.update_columns(cohort_id: course.cohorts.first.id)
    end
  end

  def down
    Course.update_all(cohort_id: nil)
  end
end

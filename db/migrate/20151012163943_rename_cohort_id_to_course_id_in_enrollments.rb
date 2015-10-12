class RenameCohortIdToCourseIdInEnrollments < ActiveRecord::Migration
  def change
    rename_column :enrollments, :cohort_id, :course_id
  end
end

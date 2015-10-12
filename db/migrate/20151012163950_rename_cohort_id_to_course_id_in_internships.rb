class RenameCohortIdToCourseIdInInternships < ActiveRecord::Migration
  def change
    rename_column :internships, :cohort_id, :course_id
  end
end

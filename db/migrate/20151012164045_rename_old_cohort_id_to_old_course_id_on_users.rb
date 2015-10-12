class RenameOldCohortIdToOldCourseIdOnUsers < ActiveRecord::Migration
  def change
    rename_column :users, :old_cohort_id, :old_course_id
  end
end

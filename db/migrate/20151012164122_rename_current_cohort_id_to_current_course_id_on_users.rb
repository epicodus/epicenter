class RenameCurrentCohortIdToCurrentCourseIdOnUsers < ActiveRecord::Migration
  def change
    rename_column :users, :current_cohort_id, :current_course_id
  end
end

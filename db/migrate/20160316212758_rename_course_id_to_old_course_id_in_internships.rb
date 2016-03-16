class RenameCourseIdToOldCourseIdInInternships < ActiveRecord::Migration
  def change
    rename_column :internships, :course_id, :old_course_id
  end
end

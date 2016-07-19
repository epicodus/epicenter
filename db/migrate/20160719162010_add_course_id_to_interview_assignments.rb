class AddCourseIdToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :course_id, :integer
  end
end

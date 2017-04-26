class AddFeedbackFromStudentToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :feedback_from_student, :text
  end
end

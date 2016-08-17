class AddRankingFromStudentToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :ranking_from_student, :integer
  end
end

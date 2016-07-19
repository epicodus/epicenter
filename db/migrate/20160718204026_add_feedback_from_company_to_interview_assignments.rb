class AddFeedbackFromCompanyToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :feedback_from_company, :text
  end
end

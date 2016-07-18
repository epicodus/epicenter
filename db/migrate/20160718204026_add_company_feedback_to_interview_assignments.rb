class AddCompanyFeedbackToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :company_feedback, :text
  end
end

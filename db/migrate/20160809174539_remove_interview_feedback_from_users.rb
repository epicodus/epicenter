class RemoveInterviewFeedbackFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :interview_feedback, :text
  end
end

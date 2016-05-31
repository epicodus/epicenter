class AddInterviewFeedbackToUsers < ActiveRecord::Migration
  def change
    add_column :users, :interview_feedback, :text
  end
end

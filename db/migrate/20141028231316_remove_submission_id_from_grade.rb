class RemoveSubmissionIdFromGrade < ActiveRecord::Migration
  def change
    remove_column :grades, :submission_id, :integer
  end
end

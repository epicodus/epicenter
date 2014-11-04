class ChangeSubmissionUserIdToStudentId < ActiveRecord::Migration
  def change
    rename_column :submissions, :user_id, :student_id
  end
end

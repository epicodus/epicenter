class ChangePaymentsUserIdToStudentId < ActiveRecord::Migration
  def change
    rename_column :payments, :user_id, :student_id
  end
end

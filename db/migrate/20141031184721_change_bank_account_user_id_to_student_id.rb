class ChangeBankAccountUserIdToStudentId < ActiveRecord::Migration
  def change
    rename_column :bank_accounts, :user_id, :student_id
  end
end

class ChangeCreditCardUserIdToStudentId < ActiveRecord::Migration
  def change
    rename_column :credit_cards, :user_id, :student_id
  end
end

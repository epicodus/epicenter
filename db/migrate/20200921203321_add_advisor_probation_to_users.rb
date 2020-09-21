class AddAdvisorProbationToUsers < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :probation, :probation_teacher
    add_column :users, :probation_advisor, :boolean
  end
end

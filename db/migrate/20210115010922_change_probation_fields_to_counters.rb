class ChangeProbationFieldsToCounters < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :probation_teacher_count, :integer
    add_column :users, :probation_advisor_count, :integer
    User.where(probation_teacher: true).update_all(probation_teacher_count: 1)
    User.where(probation_advisor: true).update_all(probation_advisor_count: 1)
  end

  def down
    remove_column :users, :probation_teacher_count
    remove_column :users, :probation_advisor_count
  end
end

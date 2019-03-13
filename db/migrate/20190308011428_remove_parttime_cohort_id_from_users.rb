class RemoveParttimeCohortIdFromUsers < ActiveRecord::Migration[5.2]
  def up
    remove_column :users, :parttime_cohort_id
  end

  def down
    add_column :users, :parttime_cohort_id
  end
end

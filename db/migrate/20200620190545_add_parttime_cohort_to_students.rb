class AddParttimeCohortToStudents < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :parttime_cohort_id, :integer
    add_index :users, :parttime_cohort_id
  end
end

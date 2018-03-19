class AddEndingCohortToUsers2 < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :ending_cohort_id, :integer
    Student.update_all("ending_cohort_id = cohort_id")
  end

  def down
    remove_column :users, :ending_cohort_id
  end
end

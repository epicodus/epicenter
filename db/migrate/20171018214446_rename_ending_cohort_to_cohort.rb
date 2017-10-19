class RenameEndingCohortToCohort < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :ending_cohort_id, :cohort_id
  end
end

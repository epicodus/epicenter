class RenameCohortIdToOldCohortId < ActiveRecord::Migration
  def change
    rename_column :users, :cohort_id, :old_cohort_id
  end
end

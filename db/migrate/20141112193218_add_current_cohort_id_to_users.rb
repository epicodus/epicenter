class AddCurrentCohortIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_cohort_id, :integer
  end
end

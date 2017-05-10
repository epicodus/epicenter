class AddStartingCohortIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :starting_cohort_id, :integer
  end
end

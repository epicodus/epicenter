class AddEndingCohortToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :ending_cohort_id, :integer
  end
end

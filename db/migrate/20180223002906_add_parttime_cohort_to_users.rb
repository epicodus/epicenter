class AddParttimeCohortToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :parttime_cohort_id, :integer
  end
end

class AddStartDateIndexToCohorts < ActiveRecord::Migration
  def change
    add_index :cohorts, :start_date
  end
end

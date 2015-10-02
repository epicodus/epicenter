class AddStartTimeToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :start_time, :string
  end
end

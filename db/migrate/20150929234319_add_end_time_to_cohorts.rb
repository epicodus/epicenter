class AddEndTimeToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :end_time, :string
  end
end

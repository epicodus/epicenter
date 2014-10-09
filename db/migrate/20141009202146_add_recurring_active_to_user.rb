class AddRecurringActiveToUser < ActiveRecord::Migration
  def change
    add_column :users, :recurring_active, :boolean
  end
end

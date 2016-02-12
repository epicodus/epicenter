class DropRecurringActiveFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :recurring_active, :boolean
  end
end

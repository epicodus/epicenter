class AddIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :recurring_active
  end
end

class AddStaffStickyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :staff_sticky, :text
  end
end

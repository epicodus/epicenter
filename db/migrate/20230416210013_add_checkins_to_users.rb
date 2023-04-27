class AddCheckinsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :checkins, :integer, default: 0
  end
end

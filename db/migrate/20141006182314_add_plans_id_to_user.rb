class AddPlansIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :plan_id, :integer
    remove_column :plans, :user_id
  end
end

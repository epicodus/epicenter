class AddOrderToPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :order, :integer
  end
end

class RemoveTotalAmountFromPlans < ActiveRecord::Migration
  def change
    remove_column :plans, :total_amount, :integer
  end
end

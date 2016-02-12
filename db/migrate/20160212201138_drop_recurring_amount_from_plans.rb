class DropRecurringAmountFromPlans < ActiveRecord::Migration
  def change
    remove_column :plans, :recurring_amount, :integer
  end
end

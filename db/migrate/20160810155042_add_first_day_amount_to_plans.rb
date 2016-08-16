class AddFirstDayAmountToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :first_day_amount, :integer
  end
end

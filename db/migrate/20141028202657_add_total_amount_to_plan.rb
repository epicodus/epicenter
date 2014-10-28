class AddTotalAmountToPlan < ActiveRecord::Migration
  class Plan < ActiveRecord::Base
  end

  def change
    add_column :plans, :total_amount, :integer
    Plan.all.each do |plan|
      plan.total_amount = (plan.recurring_amount.to_i * 8) + plan.upfront_amount
      plan.save
    end
  end
end

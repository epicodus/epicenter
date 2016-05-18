class AddLoanAndStandardToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :loan, :boolean
    add_column :plans, :standard, :boolean
  end
end

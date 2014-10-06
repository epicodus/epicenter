class RenameAmtToAmount < ActiveRecord::Migration
  def change
    rename_column :plans, :recurring_amt, :recurring_amount
    rename_column :plans, :upfront_amt, :upfront_amount
  end
end

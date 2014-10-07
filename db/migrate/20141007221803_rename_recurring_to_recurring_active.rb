class RenameRecurringToRecurringActive < ActiveRecord::Migration
  def change
    rename_column :bank_accounts, :recurring, :recurring_active
  end
end

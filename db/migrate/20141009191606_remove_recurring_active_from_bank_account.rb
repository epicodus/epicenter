class RemoveRecurringActiveFromBankAccount < ActiveRecord::Migration
  def change
    remove_column :bank_accounts, :recurring_active
  end
end

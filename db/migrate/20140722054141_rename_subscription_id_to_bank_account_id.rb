class RenameSubscriptionIdToBankAccountId < ActiveRecord::Migration
  def change
    rename_column :payments, :subscription_id, :bank_account_id
  end
end

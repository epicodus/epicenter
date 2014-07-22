class RenameSubscriptionToBankAccount < ActiveRecord::Migration
  def change
    rename_table :subscriptions, :bank_accounts
  end
end

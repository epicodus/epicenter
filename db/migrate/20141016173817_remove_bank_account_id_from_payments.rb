class RemoveBankAccountIdFromPayments < ActiveRecord::Migration
  def change
    remove_column :payments, :bank_account_id
    add_column :payments, :user_id, :integer
  end
end

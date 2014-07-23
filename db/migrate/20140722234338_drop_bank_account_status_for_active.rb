class DropBankAccountStatusForActive < ActiveRecord::Migration
  def change
    remove_column :bank_accounts, :status, :string
    add_column :bank_accounts, :active, :boolean
  end
end

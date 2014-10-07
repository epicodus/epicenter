class RenameActiveToRecurring < ActiveRecord::Migration
  def change
    rename_column :bank_accounts, :active, :recurring
  end
end

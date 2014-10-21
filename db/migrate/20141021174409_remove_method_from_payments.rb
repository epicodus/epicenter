class RemoveMethodFromPayments < ActiveRecord::Migration
  def change
    remove_column :payments, :method
  end
end

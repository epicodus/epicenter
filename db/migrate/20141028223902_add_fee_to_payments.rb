class AddFeeToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :fee, :integer, :null => false, :default => 0
  end
end

class AddRefundAmountToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :refund_amount, :integer
  end
end

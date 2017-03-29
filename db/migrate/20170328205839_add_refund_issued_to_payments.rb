class AddRefundIssuedToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :refund_issued, :boolean
  end
end

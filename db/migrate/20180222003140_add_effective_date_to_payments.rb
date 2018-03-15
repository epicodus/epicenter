class AddEffectiveDateToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :refund_date, :date
    add_column :payments, :refund_basis, :integer
  end
end

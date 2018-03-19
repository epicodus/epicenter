class RemoveRefundBasisFromPayments < ActiveRecord::Migration[5.1]
  def change
    remove_column :payments, :refund_basis, :string
  end
end

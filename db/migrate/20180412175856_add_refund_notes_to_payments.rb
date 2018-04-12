class AddRefundNotesToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :refund_notes, :string
  end
end

class AddTypeAndOriginalPaymentToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :type, :string
    add_column :payments, :original_payment_id, :integer, index: true
    PaymentBase.update_all(type: "Payment")
  end
end

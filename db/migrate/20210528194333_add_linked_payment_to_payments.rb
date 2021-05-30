class AddLinkedPaymentToPayments < ActiveRecord::Migration[5.2]
  def change
    add_reference :payments, :linked_payment, foreign_key: { to_table: :payments }
  end
end

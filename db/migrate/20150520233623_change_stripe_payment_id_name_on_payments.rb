class ChangeStripePaymentIdNameOnPayments < ActiveRecord::Migration
  def change
    rename_column :payments, :stripe_payment_id, :stripe_transaction
  end
end

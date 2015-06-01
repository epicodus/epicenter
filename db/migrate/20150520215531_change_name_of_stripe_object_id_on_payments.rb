class ChangeNameOfStripeObjectIdOnPayments < ActiveRecord::Migration
  def change
    rename_column :payments, :stripe_object_id, :stripe_payment_id
  end
end

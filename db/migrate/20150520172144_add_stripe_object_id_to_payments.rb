class AddStripeObjectIdToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :stripe_object_id, :string
  end
end

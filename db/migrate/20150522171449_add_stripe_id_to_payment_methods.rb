class AddStripeIdToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :stripe_id, :string
  end
end

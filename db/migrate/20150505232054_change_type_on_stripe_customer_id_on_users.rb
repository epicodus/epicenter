class ChangeTypeOnStripeCustomerIdOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :stripe_customer_id, :string
  end
end

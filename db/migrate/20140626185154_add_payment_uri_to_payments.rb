class AddPaymentUriToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_uri, :string
  end
end

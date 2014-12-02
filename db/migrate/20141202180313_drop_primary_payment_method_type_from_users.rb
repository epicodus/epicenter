class DropPrimaryPaymentMethodTypeFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :primary_payment_method_type, :string
  end
end

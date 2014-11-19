class RemoveOldPaymentMethodsTables < ActiveRecord::Migration
  def change
    drop_table :old_bank_accounts
    drop_table :old_credit_cards
    remove_column :payments, :old_payment_method_id
    remove_column :payments, :old_payment_method_type
  end
end

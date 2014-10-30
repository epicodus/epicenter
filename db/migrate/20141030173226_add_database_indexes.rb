class AddDatabaseIndexes < ActiveRecord::Migration
  def change
    add_index :attendance_records, :user_id
    add_index :attendance_records, :tardy
    add_index :attendance_records, :created_at
    add_index :bank_accounts, :user_id
    add_index :bank_accounts, :verified
    add_index :credit_cards, :user_id
    add_index :payments, :user_id
    add_index :payments, [:payment_method_type, :payment_method_id], :name => 'payment_method_index'
    add_index :users, :plan_id
  end
end

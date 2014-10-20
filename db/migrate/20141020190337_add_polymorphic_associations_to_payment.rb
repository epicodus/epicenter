class AddPolymorphicAssociationsToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :payment_method_id, :integer
    add_column :payments, :payment_method_type, :string
  end
end

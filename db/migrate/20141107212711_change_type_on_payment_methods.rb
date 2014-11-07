class ChangeTypeOnPaymentMethods < ActiveRecord::Migration
  def change
    rename_column :payment_methods, :real_type, :type
  end
end

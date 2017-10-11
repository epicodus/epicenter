class AddCategoryToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :category, :string
  end
end

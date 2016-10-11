class AddDescriptionToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :description, :string
  end
end

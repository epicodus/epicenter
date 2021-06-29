class AddUpfrontAmountToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :upfront_amount, :integer
  end
end

class CreateCreditCard < ActiveRecord::Migration
  def change
    create_table :credit_cards do |t|
      t.string :credit_card_uri
      t.integer :user_id

      t.timestamps
    end
  end
end

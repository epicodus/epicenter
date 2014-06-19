class AddPaymentsTable < ActiveRecord::Migration
  def change
    create_table(:payments) do |t|
      t.belongs_to :user
      t.integer :amount
      t.string :method

      t.timestamps
    end
  end
end

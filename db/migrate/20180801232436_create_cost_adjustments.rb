class CreateCostAdjustments < ActiveRecord::Migration[5.2]
  def change
    create_table :cost_adjustments do |t|
      t.references :student, index: true, foreign_key: { to_table: :users }
      t.integer :amount
      t.string :reason
    end
  end
end

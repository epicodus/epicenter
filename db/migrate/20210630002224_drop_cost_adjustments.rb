class DropCostAdjustments < ActiveRecord::Migration[5.2]
  def up
    drop_table :cost_adjustments
  end

  def down
    create_table :cost_adjustments do |t|
      t.references :student, index: true, foreign_key: { to_table: :users }
      t.integer :amount
      t.string :reason
      t.timestamps
    end
  end
end

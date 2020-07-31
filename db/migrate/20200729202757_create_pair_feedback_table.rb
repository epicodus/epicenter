class CreatePairFeedbackTable < ActiveRecord::Migration[5.2]
  def change
    create_table :pair_feedback do |t|
      t.references :student, index: true, foreign_key: { to_table: :users }
      t.references :pair, index: true, foreign_key: { to_table: :users }
      t.integer :q1_response
      t.integer :q2_response
      t.integer :q3_response
      t.string :comments
      t.timestamps
    end
  end
end

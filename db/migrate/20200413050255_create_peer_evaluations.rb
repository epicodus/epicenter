class CreatePeerEvaluations < ActiveRecord::Migration[5.2]
  def change
    create_table :peer_evaluations do |t|
      t.references :evaluator, index: true, foreign_key: { to_table: :users }
      t.references :evaluatee, index: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :peer_questions do |t|
      t.string :content
      t.string :category
      t.string :input_type
      t.integer :number
    end

    create_table :peer_responses do |t|
      t.belongs_to :peer_evaluation
      t.belongs_to :peer_question
      t.integer :score
      t.string :comment
    end
  end
end

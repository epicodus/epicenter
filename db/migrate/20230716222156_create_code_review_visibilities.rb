class CreateCodeReviewVisibilities < ActiveRecord::Migration[7.0]
  def change
    create_table :code_review_visibilities do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :code_review, null: false, foreign_key: true
      t.datetime :visible_start
      t.datetime :visible_end
      t.boolean :always_visible
      t.boolean :special_permission

      t.timestamps
    end
  end
end

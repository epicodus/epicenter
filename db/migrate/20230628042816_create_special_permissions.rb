class CreateSpecialPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :special_permissions do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :code_review, null: false, foreign_key: true

      t.timestamps
    end
  end
end

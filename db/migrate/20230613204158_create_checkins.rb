class CreateCheckins < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :checkins, :checkins_legacy
    create_table :checkins do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end

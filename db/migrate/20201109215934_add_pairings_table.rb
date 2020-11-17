class AddPairingsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :pairings do |t|
      t.references :attendance_record, index: true
      t.references :pair, index: true, foreign_key: { to_table: :users }
    end

    rename_column :attendance_records, :pair_ids, :old_pair_ids
  end
end

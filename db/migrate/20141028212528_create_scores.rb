class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer :value
      t.string :description

      t.timestamps
    end

    rename_column :grades, :score, :score_id
  end
end

class CreateDailySubmissionsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_submissions do |t|
      t.references :student, index: true, foreign_key: { to_table: :users }
      t.string :link
      t.date :date
    end
  end
end

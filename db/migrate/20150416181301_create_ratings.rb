class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :student_id
      t.integer :internship_id
      t.string :interest
      t.text :notes
      t.timestamps
    end
  end
end

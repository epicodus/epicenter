class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.integer :course_id
      t.string :student_names
      t.text :note
      t.string :location
      t.boolean :open, default: true

      t.timestamps
    end
  end
end

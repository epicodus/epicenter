class CreateClassTimesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :class_times do |t|
      t.integer :wday
      t.string :start_time
      t.string :end_time
    end

    create_join_table :class_times, :courses do |t|
      t.references :class_time
      t.references :course
    end
  end
end

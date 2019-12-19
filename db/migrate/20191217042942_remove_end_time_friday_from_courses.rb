class RemoveEndTimeFridayFromCourses < ActiveRecord::Migration[5.2]
  def up
    remove_column :courses, :end_time_friday
  end

  def down
    add_column :courses, :end_time_friday, :string
  end
end

class RemoveStartTimeAndEndTimeFromCourses < ActiveRecord::Migration[5.2]
  def change
    remove_column :courses, :start_time, :string
    remove_column :courses, :end_time, :string
  end
end

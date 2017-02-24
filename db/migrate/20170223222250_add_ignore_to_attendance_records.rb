class AddIgnoreToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :ignore, :boolean
  end
end

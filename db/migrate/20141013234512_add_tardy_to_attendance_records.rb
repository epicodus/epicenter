class AddTardyToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :tardy, :boolean
  end
end

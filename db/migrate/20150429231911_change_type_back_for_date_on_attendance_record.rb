class ChangeTypeBackForDateOnAttendanceRecord < ActiveRecord::Migration
  def change
    change_column :attendance_records, :date, :date
  end
end

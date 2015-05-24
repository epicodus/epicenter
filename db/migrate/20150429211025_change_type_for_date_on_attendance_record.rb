class ChangeTypeForDateOnAttendanceRecord < ActiveRecord::Migration
  def change
    change_column :attendance_records, :date, :datetime
  end
end

class ChangeTypeOnSignedOutTimeForAttendanceRecord < ActiveRecord::Migration
  def change
    remove_column :attendance_records, :signed_out_time
    add_column :attendance_records, :signed_out_time, :datetime
  end
end

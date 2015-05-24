class AddLeftEarlyAndSignedOutTimeToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :left_early, :boolean
    add_column :attendance_records, :signed_out_time, :time
  end
end

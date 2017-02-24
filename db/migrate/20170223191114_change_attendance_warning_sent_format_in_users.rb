class ChangeAttendanceWarningSentFormatInUsers < ActiveRecord::Migration
  def change
   remove_column :users, :attendance_warning_sent
   add_column :users, :attendance_warnings_sent, :integer
  end
end

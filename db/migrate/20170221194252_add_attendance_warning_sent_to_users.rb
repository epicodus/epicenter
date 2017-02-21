class AddAttendanceWarningSentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :attendance_warning_sent, :boolean
  end
end

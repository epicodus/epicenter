class AddStationToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :station, :string
  end
end

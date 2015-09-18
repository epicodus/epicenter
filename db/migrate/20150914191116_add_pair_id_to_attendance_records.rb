class AddPairIdToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :pair_id, :integer
  end
end

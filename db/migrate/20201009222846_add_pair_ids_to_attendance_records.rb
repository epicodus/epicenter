class AddPairIdsToAttendanceRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :attendance_records, :pair_ids, :integer, array: true, default: []
  end
end

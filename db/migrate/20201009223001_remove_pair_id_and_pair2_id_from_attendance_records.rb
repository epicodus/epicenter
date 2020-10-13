class RemovePairIdAndPair2IdFromAttendanceRecords < ActiveRecord::Migration[5.2]
  def change
    remove_column :attendance_records, :pair_id, :integer
    remove_column :attendance_records, :pair2_id, :integer
  end
end

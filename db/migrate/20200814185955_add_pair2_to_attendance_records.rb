class AddPair2ToAttendanceRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :attendance_records, :pair2_id, :integer
  end
end

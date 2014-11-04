class ChangeAttendanceRecordUserIdToStudentId < ActiveRecord::Migration
  def change
    rename_column :attendance_records, :user_id, :student_id
  end
end

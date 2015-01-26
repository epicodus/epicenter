class AddDateToAttendanceRecord < ActiveRecord::Migration
  def change
    add_column :attendance_records, :date, :date

    AttendanceRecord.all.each do |attendance_record|
      attendance_record.update(date: attendance_record.created_at.to_date)
    end
  end
end

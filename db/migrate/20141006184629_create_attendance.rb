class CreateAttendance < ActiveRecord::Migration
  def change
    create_table :attendance_records do |t|
      t.belongs_to :user

      t.timestamps
    end
  end
end

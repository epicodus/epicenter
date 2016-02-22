class AddSignInIpAddressToAttendanceRecords < ActiveRecord::Migration
  def change
    add_column :attendance_records, :sign_in_ip_address, :string
    add_column :attendance_records, :sign_out_ip_address, :string
  end
end

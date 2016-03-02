class RemoveSignInIpAddressAndSignOutIpAddressFromAttendanceRecords < ActiveRecord::Migration
  def change
    remove_column :attendance_records, :sign_in_ip_address, :string
    remove_column :attendance_records, :sign_out_ip_address, :string
  end
end

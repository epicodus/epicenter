class AddDeletedAtToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :deleted_at, :datetime
    add_index :enrollments, :deleted_at
  end
end

class AddAdminIdToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :admin_id, :integer
  end
end

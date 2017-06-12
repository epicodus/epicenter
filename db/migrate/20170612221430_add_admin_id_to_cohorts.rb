class AddAdminIdToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :admin_id, :integer
  end
end

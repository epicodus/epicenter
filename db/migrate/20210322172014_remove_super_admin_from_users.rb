class RemoveSuperAdminFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :super_admin, :boolean
  end
end

class AddAdminIdToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :admin_id, :integer
  end
end

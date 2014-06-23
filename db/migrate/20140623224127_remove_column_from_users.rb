class RemoveColumnFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :uri
    remove_column :users, :verification_uri
  end
end

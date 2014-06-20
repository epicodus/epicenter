class AddUriToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uri, :string
  end
end

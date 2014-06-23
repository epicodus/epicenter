class AddVerificationUriToUser < ActiveRecord::Migration
  def change
    add_column :users, :verification_uri, :string
  end
end

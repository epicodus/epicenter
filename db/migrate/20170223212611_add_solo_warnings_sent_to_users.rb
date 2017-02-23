class AddSoloWarningsSentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :solo_warnings_sent, :integer
  end
end

class AddOfflineAndNotesToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :offline, :boolean
    add_column :payments, :notes, :text
  end
end

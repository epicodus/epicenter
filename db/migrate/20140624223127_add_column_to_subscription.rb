class AddColumnToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :verified, :boolean
  end
end

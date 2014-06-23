class AddSubscriptionsTable < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :account_uri
      t.string :verification_uri

      t.timestamps
    end
  end
end

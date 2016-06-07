class AddReferralEmailSentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referral_email_sent, :boolean
  end
end

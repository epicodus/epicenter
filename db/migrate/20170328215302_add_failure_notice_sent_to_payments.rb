class AddFailureNoticeSentToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :failure_notice_sent, :boolean
  end
end

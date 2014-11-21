namespace :billing do
  desc "Send emails to accounts due in 3 days"
  task :email_upcoming_payees => :environment do
    BillingTasks.email_upcoming_payees
  end

  desc "Bill due bank accounts"
  task :bill_bank_accounts => :environment do
    BillingTasks.bill_bank_accounts
  end

  desc "Transfer escrow balance to Epicodus bank account"
  task :transfer_escrow => :environment do
    BillingTasks.transfer_full_escrow_balance
  end
end

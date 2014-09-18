namespace :billing do
  desc "Send emails to accounts due in 3 days"
  task :email_upcoming_payees => :environment do
    BankAccount.email_upcoming_payees
  end
end

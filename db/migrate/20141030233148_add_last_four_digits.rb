class AddLastFourDigits < ActiveRecord::Migration
  require 'balanced'

  class BankAccount < ActiveRecord::Base
  end

  class CreditCard < ActiveRecord::Base
  end

  def change
    add_column :bank_accounts, :last_four_string, :string
    add_column :credit_cards, :last_four_string, :string

    BankAccount.all.each do |bank_account|
      last_four = Balanced::BankAccount.fetch(bank_account.account_uri).account_number
      bank_account.update(last_four_string: last_four)
    end

    CreditCard.all.each do |credit_card|
      last_four = Balanced::Card.fetch(credit_card.credit_card_uri).number
      credit_card.update(last_four_string: last_four)
    end
  end
end

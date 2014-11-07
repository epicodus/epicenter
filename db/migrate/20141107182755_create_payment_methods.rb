class CreatePaymentMethods < ActiveRecord::Migration

  class PaymentMethod < ActiveRecord::Base
  end

  class CreditCard < ActiveRecord::Base
    has_many :payments, :as => :payment_method
  end

  class BankAccount < ActiveRecord::Base
    has_many :payments, :as => :payment_method
  end

  class Payment < ActiveRecord::Base
    belongs_to :payment_method, polymorphic: true
  end

  def up
    create_table :payment_methods do |t|
      t.string :account_uri
      t.string :verification_uri
      t.integer :student_id
      t.boolean :verified
      t.string :last_four_string
      t.string :real_type

      t.timestamps
    end

    add_column :payments, :new_payment_method_id, :integer

    BankAccount.all.each do |bank_account|
      payments = Payment.where(payment_method_id: bank_account.id, payment_method_type: 'BankAccount')

      pm = PaymentMethod.create(account_uri: bank_account.account_uri, real_type: "BankAccount", last_four_string: bank_account.last_four_string, student_id: bank_account.student_id, verified: bank_account.verified, verification_uri: bank_account.verification_uri)

      payments.each { |payment| payment.update!(new_payment_method_id: pm.id)}
    end

    CreditCard.all.each do |credit_card|
      payments = Payment.where(payment_method_id: credit_card.id, payment_method_type: 'CreditCard')

      pm = PaymentMethod.create(account_uri: credit_card .credit_card_uri, real_type: "CreditCard", last_four_string: credit_card.last_four_string, student_id: credit_card.student_id)

      payments.each { |payment| payment.update!(new_payment_method_id: pm.id)}
    end

    rename_column :payments, :payment_method_id, :old_payment_method_id
    rename_column :payments, :payment_method_type, :old_payment_method_type
    rename_column :payments, :new_payment_method_id, :payment_method_id

    rename_table :credit_cards, :old_credit_cards
    rename_table :bank_accounts, :old_bank_accounts
  end

  def down
    drop_table :payment_methods
    remove_column :payments, :payment_method_id

    rename_column :payments, :old_payment_method_id, :payment_method_id
    rename_column :payments, :old_payment_method_type, :payment_method_type

    rename_table :old_credit_cards, :credit_cards
    rename_table :old_bank_accounts, :bank_accounts
  end
end

class AddPolymorphicAssociationsToPayment < ActiveRecord::Migration
  class Payment < ActiveRecord::Base
    belongs_to :user
  end

  class User < ActiveRecord::Base
    has_one :bank_account
  end

  class BankAccount < ActiveRecord::Base
    belongs_to :user
  end

  def change
    add_column :payments, :payment_method_id, :integer
    add_column :payments, :payment_method_type, :string
    Payment.all.each do |payment|
      payment.payment_method_id = payment.user.bank_account.id
      payment.payment_method_type = 'BankAccount'
      payment.save
    end
  end
end

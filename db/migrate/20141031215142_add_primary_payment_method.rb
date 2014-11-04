class AddPrimaryPaymentMethod < ActiveRecord::Migration

  class CreditCard < ActiveRecord::Base
    belongs_to :user
  end

  class BankAccount < ActiveRecord::Base
    belongs_to :user
  end

  class User < ActiveRecord::Base
  end

  class Student < User
    has_one :credit_card
    has_one :bank_account

    def has_payment_method
      credit_card.present? || (bank_account.present? && bank_account.verified == true)
    end

    def primary_payment_method
      credit_card.present? ? credit_card : bank_account
    end
  end

  def change
    add_column :users, :primary_payment_method_type, :string
    add_column :users, :primary_payment_method_id, :integer

    Student.all.each do |student|
      if student.has_payment_method
        student.primary_payment_method_type = student.primary_payment_method.class.name.split('::').last
        student.primary_payment_method_id = student.primary_payment_method.id
        student.save
      end
    end
  end
end

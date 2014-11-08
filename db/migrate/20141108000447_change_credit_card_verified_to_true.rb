class ChangeCreditCardVerifiedToTrue < ActiveRecord::Migration
  class PaymentMethod < ActiveRecord::Base
  end

  def up
    PaymentMethod.where(type: 'CreditCard').each do |credit_card|
      credit_card.update!(verified: true)
    end
  end

  def down
    PaymentMethod.where(type: 'CreditCard').each do |credit_card|
      credit_card.update!(verified: nil)
    end
  end
end

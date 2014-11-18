class AddStatusToPayments < ActiveRecord::Migration

  class Payment < ActiveRecord::Base
  end

  def change
    add_column :payments, :status, :string

    Payment.all.each do |payment|
      payment.update(status: "succeeded")
    end
  end
end

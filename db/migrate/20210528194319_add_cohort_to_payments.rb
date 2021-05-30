class AddCohortToPayments < ActiveRecord::Migration[5.2]
  def change
    add_reference :payments, :cohort, foreign_key: true
  end
end

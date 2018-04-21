class AddQboDocNumbersToPayment < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :qbo_doc_numbers, :string, array: true, default: []
  end
end

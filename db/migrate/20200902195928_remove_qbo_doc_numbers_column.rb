class RemoveQboDocNumbersColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :payments, :qbo_doc_numbers
  end
end

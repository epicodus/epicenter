class AddQboJournalEntryIdsToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :qbo_journal_entry_ids, :string, array: true, default: []
  end
end

class AddJournalToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :journal, :text
  end
end

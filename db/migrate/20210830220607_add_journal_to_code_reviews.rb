class AddJournalToCodeReviews < ActiveRecord::Migration[5.2]
  def change
    add_column :code_reviews, :journal, :boolean
  end
end

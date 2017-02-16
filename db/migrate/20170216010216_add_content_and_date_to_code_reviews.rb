class AddContentAndDateToCodeReviews < ActiveRecord::Migration
  def change
    add_column :code_reviews, :content, :text
    add_column :code_reviews, :date, :date
  end
end

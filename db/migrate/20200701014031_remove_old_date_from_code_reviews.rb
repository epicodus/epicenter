class RemoveOldDateFromCodeReviews < ActiveRecord::Migration[5.2]
  def up
    remove_column :code_reviews, :date
  end

  def down
    add_column :code_reviews, :date, :date
    CodeReview.where.not(due_date:nil).each do |cr|
      cr.update_columns(date: cr.due_date)
    end
  end
end

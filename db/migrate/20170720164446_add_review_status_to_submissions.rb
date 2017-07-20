class AddReviewStatusToSubmissions < ActiveRecord::Migration[5.1]
  def change
    add_column :submissions, :review_status, :string
  end
end

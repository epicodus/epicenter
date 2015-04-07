class RenameCodeReviewsToCodeReviews < ActiveRecord::Migration
  def change
    rename_table :assessments, :code_reviews
    rename_column :submissions, :assessment_id, :code_review_id
    rename_column :requirements, :assessment_id, :code_review_id
  end
end

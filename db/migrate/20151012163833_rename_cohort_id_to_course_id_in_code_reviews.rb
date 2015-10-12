class RenameCohortIdToCourseIdInCodeReviews < ActiveRecord::Migration
  def change
    rename_column :code_reviews, :cohort_id, :course_id
  end
end

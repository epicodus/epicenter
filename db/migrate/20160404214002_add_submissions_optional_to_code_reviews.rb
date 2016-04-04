class AddSubmissionsOptionalToCodeReviews < ActiveRecord::Migration
  def change
    add_column :code_reviews, :submissions_optional, :boolean
  end
end

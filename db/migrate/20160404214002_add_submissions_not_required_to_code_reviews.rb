class AddSubmissionsNotRequiredToCodeReviews < ActiveRecord::Migration
  def change
    add_column :code_reviews, :submissions_not_required, :boolean
  end
end

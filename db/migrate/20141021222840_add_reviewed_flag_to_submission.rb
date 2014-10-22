class AddReviewedFlagToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :needs_review, :boolean
  end
end

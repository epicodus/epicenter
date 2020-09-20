class AddCodeReviewWeeksToLanguages < ActiveRecord::Migration[5.2]
  def change
    remove_column :languages, :number_of_weeks
  end
end

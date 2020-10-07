class NormalizeCodeReviewTitles < ActiveRecord::Migration[5.2]
  def change
    CodeReview.select { |cr| cr.title != cr.title.strip }.each do |cr|
      cr.update_columns(title: cr.title.strip)
    end
  end
end

class AddGithubPathToCodeReviews < ActiveRecord::Migration[5.2]
  def change
    add_column :code_reviews, :github_path, :string
  end
end

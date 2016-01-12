class AddIndexToSubmissions < ActiveRecord::Migration
  def change
    add_index :submissions, :student_id
    add_index :submissions, :code_review_id
  end
end

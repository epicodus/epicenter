class AddStudentSignatureToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :student_signature, :string
  end
end

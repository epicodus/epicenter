class AddStudentIdToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :student_id, :integer
  end
end

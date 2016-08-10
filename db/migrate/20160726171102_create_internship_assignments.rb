class CreateInternshipAssignments < ActiveRecord::Migration
  def change
    create_table :internship_assignments do |t|
      t.integer :student_id
      t.integer :internship_id
      t.integer :course_id

      t.timestamps
    end
  end
end

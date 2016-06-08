class CreateInterviewAssignments < ActiveRecord::Migration
  def change
    create_table :interview_assignments do |t|
      t.integer :student_id
      t.integer :internship_id

      t.timestamps
    end
  end
end

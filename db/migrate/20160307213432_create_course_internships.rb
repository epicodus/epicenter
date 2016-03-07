class CreateCourseInternships < ActiveRecord::Migration
  def change
    create_table :course_internships do |t|
      t.integer :course_id
      t.integer :internship_id
    end
  end
end

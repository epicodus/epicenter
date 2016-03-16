class AddInternshipCourseToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :internship_course, :boolean
  end
end

class AddInternshipAssignmentsVisibleToCourses < ActiveRecord::Migration[5.2]
  def up
    add_column :courses, :internship_assignments_visible, :boolean
    Course.internship_courses.where('start_date < ?', Date.today).update_all(internship_assignments_visible: true)
  end

  def down
    remove_column :courses, :internship_assignments_visible
  end
end

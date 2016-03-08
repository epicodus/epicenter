class MigrateCourseIdFromInternshipsToCourseInternships < ActiveRecord::Migration
  def up
    Internship.all.each do |internship|
      CourseInternship.create(internship_id: internship.id, course_id: internship.course_id)
    end
  end

  def down
    CourseInternship.destroy_all
  end
end

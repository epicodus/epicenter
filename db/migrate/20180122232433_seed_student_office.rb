class SeedStudentOffice < ActiveRecord::Migration[5.1]
  def up
    Student.with_deleted.each do |student|
      first_course = student.courses_with_withdrawn.first
      student.update(office: first_course.office) if first_course
    end
  end
end

class AddStudentIdAndCohortIdToEnrollments < ActiveRecord::Migration
  def up
    Student.find_by_sql("SELECT id, cohort_id FROM users").each do |student|
      Enrollment.create(student_id: student.id, cohort_id: student.read_attribute(:cohort_id))
    end
  end

  def down
    Enrollment.destroy_all
  end
end

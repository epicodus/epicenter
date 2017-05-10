desc "one-time task to permanently erase deleted enrollments where student never attended"
task :destroy_enrollments_withdrawn_before_start_date => [:environment] do
  Enrollment.only_deleted.each do |enrollment|
    student = Student.with_deleted.find(enrollment.student_id)
    course = enrollment.course
    if (enrollment.deleted_at < course.start_date) || (student.attendance_records_for(:all, course) == 0 && course.language.level != 4)
      enrollment.really_destroy!
    end
  end
end

class EnrollmentsController < ApplicationController
  def destroy
    student = Student.find(params[:id])
    course = Course.find(params[:course_id])
    enrollment = Enrollment.find_by(course_id: course.id, student_id: student.id)
    enrollment.destroy
    redirect_to student_path(student.id), notice: "#{course.description} has been removed"
  end
end

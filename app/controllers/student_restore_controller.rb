class StudentRestoreController < ApplicationController

  def update
    authorize! :manage, Enrollment
    student = Student.only_deleted.find(params[:student_id])
    student.restore
    redirect_to student_courses_path(student)
  end

end

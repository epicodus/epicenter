class StudentsController < ApplicationController

  include AuthenticationHelper

  before_filter :authenticate_student_and_admin

  def index
    @students = current_admin.current_course.students
  end

  def show
    @student = Student.find(params[:id])
  end

  def update
    if current_admin
      student = Student.find(params[:id])
      if student.update(student_params)
        redirect_to :back, notice: "Courses for #{student.name} have been updated"
      else
        redirect_to :back, alert: "There was an error."
      end
    elsif current_student
      student = current_user
      if student.update(student_params)
        redirect_to :back, notice: "Primary payment method has been updated."
      else
        redirect_to :back, alert: "There was an error."
      end
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id, :course_id)
  end
end

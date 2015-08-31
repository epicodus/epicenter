class StudentsController < ApplicationController

  include AuthenticationHelper
  
  before_filter :authenticate_student_and_admin

  def index
    @students = current_admin.current_cohort.students
  end

  def show
    @student = Student.find(params[:id])
    @internships = @student.internships_sorted_by_interest
  end

  def update
    @student = current_user
    if @student.update(student_params)
      redirect_to :back, notice: "Primary payment method has been updated."
    else
      redirect_to :back, alert: "There was an error."
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id)
  end
end

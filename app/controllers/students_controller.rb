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
    @student = current_user if current_student
    @student = Student.find(params[:id]) if current_admin
    if @student.update(student_params)
      redirect_to :back, notice: "Primary payment method has been updated." if current_student
      redirect_to :back, notice: "#{@student.name}'s cohorts have been updated" if current_admin
    else
      redirect_to :back, alert: "There was an error."
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id, :cohort_id)
  end
end

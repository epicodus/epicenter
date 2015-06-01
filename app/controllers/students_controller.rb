class StudentsController < ApplicationController
  def update
    @student = current_user
    if @student.update(student_params)
      redirect_to :back, notice: "Primary payment method has been updated."
    else
      redirect_to :back, alert: "There was an error."
    end
  end

  def index
    @students = current_admin.current_cohort.students
  end

  def internships
    @student = Student.find(params[:student_id])
    @internships = @student.cohort.internships_sorted_by_interest(@student)
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id)
  end
end

class StudentsController < ApplicationController
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
    params.require(:student).permit(:primary_payment_method_type, :primary_payment_method_id)
  end
end

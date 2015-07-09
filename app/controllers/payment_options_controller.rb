class PaymentOptionsController < ApplicationController
  include SignatureUpdater

  before_filter :authenticate_student!

  def new
    @student = current_student
    update_signature_request
  end

  def create
    @student = current_student
    current_student.update(student_params)
    redirect_to root_path
  end

  def student_params
    params.require(:student).permit(:plan_id)
  end
end

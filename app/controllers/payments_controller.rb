class PaymentsController < ApplicationController
  authorize_resource
  before_filter :ensure_student_has_primary_payment_method

  def index
    @student = Student.find(params[:student_id])
    @payments = @student.payments
    if @student.upfront_payment_due?
      @payment = Payment.new(amount: @student.upfront_amount_with_fees)
    end
  end

  def show
    @student = Student.find(params[:student_id])
    @payment = Payment.find(params[:id])
  end

private
  def ensure_student_has_primary_payment_method
    @student = Student.find(params[:student_id])
    redirect_to payment_methods_path if !@student.primary_payment_method
  end
end

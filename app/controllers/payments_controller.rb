class PaymentsController < ApplicationController
  authorize_resource
  before_filter :ensure_student_has_primary_payment_method, except: [:show, :update]

  def index
    @student = Student.find(params[:student_id])
    @payments = @student.payments
    authorize! :manage, @student
    if @student.upfront_payment_due?
      @payment = Payment.new(amount: @student.upfront_amount_with_fees)
    end
  end

  def show
    @payment = Payment.find(params[:id])
    authorize! :read, @payment
  end

  def update
    @payment = Payment.find(params[:id])
    if @payment.update(payment_params)
      redirect_to student_payments_path(@payment.student)
    else
      render 'show'
    end
  end

private
  def payment_params
    params.require(:payment).permit(:refund_amount)
  end

  def ensure_student_has_primary_payment_method
    student = Student.find(params[:student_id])
    redirect_to payment_methods_path if !student.primary_payment_method
  end
end

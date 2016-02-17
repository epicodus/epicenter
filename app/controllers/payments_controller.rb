class PaymentsController < ApplicationController
  authorize_resource
  before_filter :ensure_student_has_primary_payment_method, except: [:show, :update]

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, @student
    if current_student && @student.upfront_payment_due?
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
      redirect_to student_payments_path(@payment.student), notice: "Refund successfully issued for #{@payment.student.name}."
    else
      render 'show'
    end
  end

private
  def payment_params
    format_refund_amount
    params.require(:payment).permit(:refund_amount)
  end

  def format_refund_amount
    amount = params[:payment][:refund_amount]
    if amount.include?('.')
      amount.slice!('.')
    else
      params[:payment][:refund_amount] = amount.to_i * 100
    end
  end

  def ensure_student_has_primary_payment_method
    student = Student.find(params[:student_id])
    if current_student && !student.primary_payment_method
      redirect_to payment_methods_path
    end
  end
end

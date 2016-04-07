class PaymentsController < ApplicationController
  authorize_resource
  before_filter :ensure_student_has_primary_payment_method, except: [:update]

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, @student
    if current_student && @student.upfront_payment_due?
      @payment = Payment.new(amount: @student.upfront_amount_with_fees)
    elsif current_admin
      @payment = Payment.new
    end
  end

  def create
    @student = Student.find(params[:student_id])
    @payment = Payment.new(payment_params)
    if @payment.save
      redirect_to student_payments_path(@student), notice: "Manual payment successfully made for #{@student.name}."
    else
      render 'index'
    end
  end

  def update
    @payment = Payment.find(params[:id])
    if @payment.update(payment_params)
      redirect_to student_payments_path(@payment.student), notice: "Refund successfully issued for #{@payment.student.name}."
    else
      @student = @payment.student
      render 'index'
    end
  end

private
  def payment_params
    modify_amounts(params[:payment][:refund_amount], params[:payment][:amount])
    params.require(:payment).permit(:refund_amount, :amount, :student_id, :payment_method_id, :offline, :notes)
  end

  def modify_amounts(refund_amount, payment_amount)
    if refund_amount.try(:include?, '.')
      refund_amount.slice!('.')
    elsif refund_amount
      params[:payment][:refund_amount] = refund_amount.to_i * 100
    elsif payment_amount.try(:include?, '.')
      payment_amount.slice!('.')
    elsif payment_amount
      params[:payment][:amount] = payment_amount.to_i * 100
    end
  end

  def ensure_student_has_primary_payment_method
    student = Student.find(params[:student_id])
    if current_student && !student.primary_payment_method
      redirect_to payment_methods_path
    end
  end
end

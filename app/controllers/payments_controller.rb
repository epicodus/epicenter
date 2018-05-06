class PaymentsController < ApplicationController
  authorize_resource
  before_action :ensure_student_has_primary_payment_method

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

private
  def payment_params
    modify_amounts(params[:payment][:amount])
    params.require(:payment).permit(:amount, :student_id, :payment_method_id, :offline, :notes, :category)
  end

  def modify_amounts(payment_amount)
    if payment_amount
      if payment_amount.try(:include?, '.')
        payment_amount.slice!('.')
      else
        params[:payment][:amount] = payment_amount.to_i * 100
      end
    end
  end

  def ensure_student_has_primary_payment_method
    student = Student.find(params[:student_id])
    if current_student && !student.primary_payment_method
      redirect_to payment_methods_path
    end
  end
end

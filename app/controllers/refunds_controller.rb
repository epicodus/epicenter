class RefundsController < ApplicationController
  authorize_resource

  def create
    @student = Student.find(params[:student_id])
    @refund = Refund.new(refund_params)
    if @refund.save
      redirect_to student_payments_path(@student), notice: "Refund successfully issued for #{@student.name}."
    else
      @payment = Payment.new
      render 'payments/index'
    end
  end

private
  def refund_params
    modify_amounts(params[:refund][:refund_amount])
    params.require(:refund).permit(:offline, :refund_amount, :refund_date, :refund_notes, :original_payment_id).merge(student_id: @student.id)
  end

  def modify_amounts(refund_amount)
    if refund_amount
      if refund_amount.try(:include?, '.')
        refund_amount.slice!('.')
      else
        params[:refund][:refund_amount] = refund_amount.to_i * 100
      end
    end
  end
end

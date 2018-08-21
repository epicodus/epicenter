class CostAdjustmentsController < ApplicationController
  include ActionView::Helpers::NumberHelper  #for number_to_currency
  authorize_resource

  def create
    @student = Student.find(params[:student_id])
    @cost_adjustment = CostAdjustment.new(cost_adjustment_params)
    @cost_adjustment.student = @student
    if @cost_adjustment.save
      notice = @cost_adjustment.amount > 0 ? "#{@student.name} tuition increased by #{number_to_currency(@cost_adjustment.amount / 100.00)}." : "#{@student.name} tuition decreased by #{number_to_currency(@cost_adjustment.amount / -100.00)}."
      redirect_to student_payments_path(@student), notice: notice
    else
      redirect_to student_payments_path(@student), alert: "Unable to make student tuition adjustment."
    end
  end

  def destroy
    student = Student.find(params[:student_id])
    cost_adjustment = CostAdjustment.find(params[:id])
    cost_adjustment.destroy
    redirect_to student_payments_path(student), notice: "Deleted cost adjustment"
  end

private
  def cost_adjustment_params
    modify_amounts(params[:cost_adjustment][:amount])
    params.require(:cost_adjustment).permit(:amount, :reason)
  end

  def modify_amounts(amount)
    if amount.try(:include?, '.')
      amount.slice!('.')
    else
      params[:cost_adjustment][:amount] = amount.to_i * 100
    end
  end
end

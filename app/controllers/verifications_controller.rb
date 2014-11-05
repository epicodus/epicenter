class VerificationsController < ApplicationController
  before_action :authenticate_student!

  def edit
    @verification = Verification.new
  end

  def update
    @verification = Verification.new(params[:verification].merge(bank_account: current_student.bank_account))
    if @verification.confirm
      flash[:notice] = "Your bank account has been confirmed."
      redirect_to payments_path
    else
      render :edit
    end
  end
end

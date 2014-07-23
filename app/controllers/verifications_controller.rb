class VerificationsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @verification = Verification.new
  end

  def update
    @verification = Verification.new(params[:verification].merge(bank_account: current_user.bank_account))
    if @verification.confirm
      flash[:notice] = "Your account has been confirmed and your first payment made."
      redirect_to payments_path
    else
      render :edit
    end
  end
end

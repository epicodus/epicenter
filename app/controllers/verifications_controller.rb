class VerificationsController < ApplicationController
  before_action :authenticate_student!

  def edit
    @bank_account = BankAccount.find(params[:bank_account_id])
    @verification = Verification.new
  end

  def update
    @bank_account = BankAccount.find(params[:bank_account_id])
    @verification = Verification.new(params[:verification].merge(bank_account: @bank_account))
    if @verification.confirm
      flash[:notice] = "Your bank account has been confirmed."
      redirect_to payment_methods_path
    else
      render :edit
    end
  end
end

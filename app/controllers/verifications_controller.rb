class VerificationsController < ApplicationController
  authorize_resource

  def edit
    @bank_account = BankAccount.find(params[:bank_account_id])
    @verification = Verification.new
  end

  def update
    @bank_account = BankAccount.find(params[:bank_account_id])
    @verification = Verification.new(params[:verification].merge(bank_account: @bank_account))
    if @verification.confirm
      redirect_to payment_methods_path, notice: "Your bank account has been confirmed."
    else
      render :edit
    end
  end
end

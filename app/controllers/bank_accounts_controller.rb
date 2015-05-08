class BankAccountsController < ApplicationController
  authorize_resource

  def new
    @bank_account = BankAccount.new
  end

  def create
    @bank_account = BankAccount.new(bank_account_params.merge(student: current_student))
    unless @bank_account.save
      render :new
    end
  end

  def edit
    @bank_account = BankAccount.find(params[:bank_account_id])
  end

  def update
    @bank_account = BankAccount.find(params[:bank_account_id])
    if @bank_account.update(bank_account_params)
      redirect_to payment_methods_path, notice: "Your bank account has been confirmed."
    else
      render :edit
    end
  end

private
  def bank_account_params
    params.require(:bank_account).permit(:first_depost, :second_deposit, :stripe_token)
  end
end

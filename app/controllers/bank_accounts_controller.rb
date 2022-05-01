class BankAccountsController < ApplicationController
  authorize_resource

  def new
    @bank_account = BankAccount.new
  end

  def create
    @bank_account = BankAccount.new(bank_account_params.merge(student: current_student))
    if @bank_account.save
      respond_to do |format|
        format.html { render :create } # setup manually
        format.js do # setup via Plaid
          flash[:notice] = "Your bank account has been confirmed but not yet charged."
          render js: "window.location.pathname ='#{student_payments_path(current_student)}'"
        end
      end
    else
      respond_to do |format|
        format.html { render :new } # setup manually
        format.js do # setup via Plaid
          flash[:alert] = "There was a problem linking your bank account."
          render js: "window.location.pathname ='#{payment_methods_path}'"
        end
      end
    end
  end

  def edit
    @bank_account = BankAccount.find(params[:id])
  end

  def update
    @bank_account = BankAccount.find(params[:id])
    if @bank_account.update(bank_account_params)
      @bank_account.student.update(primary_payment_method: @bank_account) if !@bank_account.student.primary_payment_method
      redirect_to student_payments_path(@bank_account.student), notice: "Your bank account has been confirmed but not yet charged."
    else
      render :edit
    end
  end

  def create_plaid_link_token
    bank_account = BankAccount.new(student: current_student)
    link_token = bank_account.create_plaid_link_token
    render json: {:status => 200, :link_token => link_token} and return
  end

private
  def bank_account_params
    params.require(:bank_account).permit(:first_deposit, :second_deposit, :stripe_token, :plaid_account_id, :plaid_public_token)
  end
end

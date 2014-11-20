class CreditCardsController < ApplicationController
  authorize_resource

  def new
    @credit_card = CreditCard.new
  end

  def create
    @credit_card = CreditCard.create(credit_card_params.merge(student: current_student))
    if @credit_card.save
      redirect_to payment_methods_path, notice: "Your credit card has been added."
    else
      render :new
    end
  end

private

  def credit_card_params
    params.require(:credit_card).permit(:account_uri)
  end
end

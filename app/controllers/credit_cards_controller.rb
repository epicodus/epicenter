class CreditCardsController < ApplicationController
  before_action :authenticate_user!

  def new
    @credit_card = CreditCard.new
  end

  def create
    @credit_card = CreditCard.create(credit_card_params.merge(student: current_user))
    if @credit_card.save
      flash[:notice] = "Your credit card has been added."
      redirect_to payments_path
    else
      render :new
    end
  end

private

  def credit_card_params
    params.require(:credit_card).permit(:credit_card_uri)
  end
end

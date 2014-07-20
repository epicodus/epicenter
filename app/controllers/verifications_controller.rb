class VerificationsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @verification = Verification.new
  end

  def update
    @verification = Verification.new(params[:verification].merge(subscription: current_user.subscription))
    if @verification.confirm
      redirect_to current_user, notice: 'Thank you! Your account has been confirmed.'
    else
      render :edit
    end
  end
end
